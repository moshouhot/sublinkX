import request from "@/utils/request";

export function getTemp(){
  return request({
    url: "/api/v1/template/get",
    method: "get",
  });
}

// 新增：获取单个模版内容
export function getTempContent(filename: string){
  return request({
    url: "/api/v1/template/content",
    method: "get",
    params: { filename },
  });
}

export function AddTemp(data: any){
  return request({
    url: "/api/v1/template/add",
    method: "post",
    data,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
export function UpdateTemp(data: any){
  return request({
    url: "/api/v1/template/update",
    method: "post",
    data,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
export function DelTemp(data: any){
  return request({
    url: "/api/v1/template/delete",
    method: "post",
    data,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
