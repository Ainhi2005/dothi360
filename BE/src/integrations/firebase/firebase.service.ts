import{firebaseMessaging}from'../../config/firebase';
export class FirebaseService{async send(tokens:string[],title:string,body:string,data:Record<string,string>={}){if(!tokens.length)return{successCount:0,failureCount:0,responses:[]};return firebaseMessaging().sendEachForMulticast({tokens,notification:{title,body},data});}}
