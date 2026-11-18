import axios,{type InternalAxiosRequestConfig}from'axios';
const baseURL=import.meta.env.VITE_API_URL??'http://localhost:3000/api/v1';let accessToken:string|null=null;let currentUser:Record<string,any>|null=null;let refreshing:Promise<string|null>|null=null;
export const setSession=(token:string|null,user?:Record<string,any>|null)=>{accessToken=token;if(user!==undefined)currentUser=user};export const getCurrentUser=()=>currentUser;
export const api=axios.create({baseURL,timeout:20000,withCredentials:true,headers:{'X-Client-Type':'admin-web'}});
api.interceptors.request.use(c=>{if(accessToken)c.headers.Authorization=`Bearer ${accessToken}`;return c});
async function refresh(){if(!refreshing)refreshing=axios.post(`${baseURL}/auth/refresh`,{}, {withCredentials:true,headers:{'X-Client-Type':'admin-web'}}).then(r=>{setSession(r.data.data.access_token,r.data.data.user);return r.data.data.access_token as string}).catch(()=>{setSession(null,null);return null}).finally(()=>{refreshing=null});return refreshing;}
api.interceptors.response.use(r=>r,async error=>{const config=error.config as InternalAxiosRequestConfig&{_retried?:boolean};if(error.response?.status===401&&!config?._retried&&!config?.url?.includes('/auth/')){config._retried=true;const token=await refresh();if(token){config.headers.Authorization=`Bearer ${token}`;return api(config)}}return Promise.reject(error)});
export async function restoreSession(){const token=await refresh();if(!token)return false;try{const r=await api.get('/auth/me');if(r.data.data.role!=='ADMIN'){setSession(null,null);return false}currentUser=r.data.data;return true}catch{return false}}
export async function logout(){try{await api.post('/auth/logout',{})}finally{setSession(null,null)}}
export const errorMessage=(error:unknown)=>axios.isAxiosError(error)?error.response?.data?.message??'Không thể kết nối máy chủ':'Đã xảy ra lỗi không xác định';
