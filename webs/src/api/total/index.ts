import request from "@/utils/request";
export function getSubTotal() {
  return request({
    url: "/api/v1/total/sub",
    method: "get",
  });
}
export function getNodeTotal() {
  return request({
    url: "/api/v1/total/node",
    method: "get",
  });
}
export function getVersion() {
  return request({
    url: "/api/v1/version",
    method: "get",
  });
}