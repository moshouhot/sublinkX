package node

import (
	"os"
	"path/filepath"
	"testing"

	"gopkg.in/yaml.v3"
)

func writeTestClashTemplate(t *testing.T) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "template.yaml")
	if err := os.WriteFile(path, []byte("proxies: []\nproxy-groups: []\n"), 0600); err != nil {
		t.Fatalf("write test template: %v", err)
	}
	return path
}

func decodeTestProxies(t *testing.T, data []byte) []Proxy {
	t.Helper()
	var config struct {
		Proxies []Proxy `yaml:"proxies"`
	}
	if err := yaml.Unmarshal(data, &config); err != nil {
		t.Fatalf("decode generated YAML: %v", err)
	}
	return config.Proxies
}

func TestEncodeClashKeepsVLESSRealityOptionsPerNode(t *testing.T) {
	links := []string{
		"vless://81057ca5-999f-4226-b1a3-ba23eb577d98@us.666606.xyz:37275?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=xFckrphDWEi2dxqI-OOFUu_WehxhBedjnbrkfuza8A4&sid=ae13bd099fc8f4bf&type=tcp&headerType=none#US-DM0",
		"vless://98bfdd15-6b16-4685-a20a-f1c733eb6e90@us.666606.xyz:20842?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI&sid=a3f8c2d61fe3ec38&type=tcp&headerType=none#US-DM1",
		"vless://ce802215-d132-4778-ac54-3f2191f6f00a@us.666606.xyz:35473?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI&sid=a3f8c2d61fe3ec38&type=tcp&headerType=none#US-DM2",
		"vless://6b2a494b-8aa7-4222-b227-1e158c2e8118@us.666606.xyz:36660?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI&sid=a3f8c2d61fe3ec38&type=tcp&headerType=none#US-DM3",
		"vless://ea0711ed-32a6-4f1e-b056-6db92abeed07@us.666606.xyz:36748?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI&sid=a3f8c2d61fe3ec38&type=tcp&headerType=none#US-DM4",
	}
	expected := map[string]struct {
		port int
		uuid string
		pbk  string
		sid  string
	}{
		"US-DM0": {37275, "81057ca5-999f-4226-b1a3-ba23eb577d98", "xFckrphDWEi2dxqI-OOFUu_WehxhBedjnbrkfuza8A4", "ae13bd099fc8f4bf"},
		"US-DM1": {20842, "98bfdd15-6b16-4685-a20a-f1c733eb6e90", "HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI", "a3f8c2d61fe3ec38"},
		"US-DM2": {35473, "ce802215-d132-4778-ac54-3f2191f6f00a", "HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI", "a3f8c2d61fe3ec38"},
		"US-DM3": {36660, "6b2a494b-8aa7-4222-b227-1e158c2e8118", "HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI", "a3f8c2d61fe3ec38"},
		"US-DM4": {36748, "ea0711ed-32a6-4f1e-b056-6db92abeed07", "HOX22wP67s1aX6ZnDo_2PCrctnH682x-EKlxTFFHFzI", "a3f8c2d61fe3ec38"},
	}

	data, err := EncodeClash(links, SqlConfig{Clash: writeTestClashTemplate(t), Udp: true})
	if err != nil {
		t.Fatalf("EncodeClash: %v", err)
	}
	proxies := decodeTestProxies(t, data)
	if len(proxies) != len(expected) {
		t.Fatalf("generated %d proxies, want %d", len(proxies), len(expected))
	}
	for _, proxy := range proxies {
		want, ok := expected[proxy.Name]
		if !ok {
			t.Errorf("unexpected proxy %q", proxy.Name)
			continue
		}
		if proxy.Port != want.port || proxy.Uuid != want.uuid {
			t.Errorf("%s has port/uuid %d/%s, want %d/%s", proxy.Name, proxy.Port, proxy.Uuid, want.port, want.uuid)
		}
		if proxy.Reality_opts["public-key"] != want.pbk || proxy.Reality_opts["short-id"] != want.sid {
			t.Errorf("%s has Reality options %v, want public-key=%s short-id=%s", proxy.Name, proxy.Reality_opts, want.pbk, want.sid)
		}
		if proxy.Grpc_opts != nil {
			t.Errorf("%s unexpectedly has grpc-opts: %v", proxy.Name, proxy.Grpc_opts)
		}
	}
}

func TestEncodeClashEmitsGRPCOptionsForGRPCNetwork(t *testing.T) {
	link := "vless://81057ca5-999f-4226-b1a3-ba23eb577d98@us.666606.xyz:37275?encryption=none&security=reality&sni=www.coophec.com&fp=chrome&pbk=xFckrphDWEi2dxqI-OOFUu_WehxhBedjnbrkfuza8A4&sid=ae13bd099fc8f4bf&type=grpc&serviceName=proxy&mode=multi#grpc"
	data, err := EncodeClash([]string{link}, SqlConfig{Clash: writeTestClashTemplate(t)})
	if err != nil {
		t.Fatalf("EncodeClash: %v", err)
	}
	proxies := decodeTestProxies(t, data)
	if len(proxies) != 1 {
		t.Fatalf("generated %d proxies, want 1", len(proxies))
	}
	if got := proxies[0].Grpc_opts["grpc-mode"]; got != "multi" {
		t.Errorf("grpc-mode = %v, want multi", got)
	}
	if got := proxies[0].Grpc_opts["grpc-service-name"]; got != "proxy" {
		t.Errorf("grpc-service-name = %v, want proxy", got)
	}
}
