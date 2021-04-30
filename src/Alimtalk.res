let parseEnvVar = (env, key) => {
  switch env->Js.Dict.get(key) {
  | None => `ENV ${key} IS REQUIRED`->Js.Exn.raiseError
  | Some(key) => key
  }
}

let sendAlimtalk = () => {
  // TODO: Option으로 처리 변경
  let env = Node.Process.process["env"]
  let apiURL = env->parseEnvVar("NHN_ALIMTALK_NHN_API_URL")
  let plusFriendID = env->parseEnvVar("NHN_ALIMTALK_NHN_PLUS_FRIEND_ID")
  let appKey = env->parseEnvVar("NHN_ALIMTALK_NHN_APP_KEY")
  let secretKey = env->parseEnvVar("NHN_ALIMTALK_NHN_SECRET_KEY")

  let getButton = (order, btnType, name, schemeIos, schemeAndroid) =>
    {
      "ordering": order,
      "type": btnType,
      "name": name,
      "schemeIos": schemeIos,
      "schemeAndroid": schemeAndroid,
    }

  let buttons = [
    getButton(1, "AL", `정보 입력하기`, "http://farm.fmorning.com/lmi4gf", "http://farm.fmorning.com/lmi4gf"),
    getButton(2, "AL", `농자재 쿠폰 받기`, "http://m.farmmorningstore.com/exec/front/newcoupon/IssueDownload?coupon_no=6068948950700000357&utm_campaign=farmstore&utm_source=kakaotalk&utm_medium=crm&utm_content=farmstore_alimtalk_welcome_0407", "http://m.farmmorningstore.com/exec/front/newcoupon/IssueDownload?coupon_no=6068948950700000357&utm_campaign=farmstore&utm_source=kakaotalk&utm_medium=crm&utm_content=farmstore_alimtalk_welcome_0407")
  ]


  let message = `안녕하세요. ~~님
팜모닝 가입을 축하드립니다! 🎉

📍 ~~님의 작물과 농장 정보를 입력해주세요. 작물 별로, 병해충 별로 마음 편히 농사 지으실 수 있게 유용한 정보들을 전달해드리겠습니다. 

📍 또한 팜모닝 회원분들을 위해 농자재 상점 20% 할인 쿠폰을 전달드리고 있으니 지금 받아가세요! ❤️`

  let payload = {
    "plusFriendId": plusFriendID,
    "templateCode": "welcomeinfo",
    "recipientList": [
      {
        "recipientNo": "01072776765",
        "content": message,
        "buttons": buttons,
      },
    ],
  }

  let url = apiURL ++ "/alimtalk/v1.5/appkeys/" ++ appKey ++ "/raw-messages"
  let headers = Axios.Headers.fromObj({
    "Content-type": "application/json;charset=UTF-8",
    "X-Secret-Key": secretKey
  })
  
  let config = Axios.makeConfig(~headers, ())
  Axios.postDatac(url, payload, config) |> Js.Promise.then_(response => {
    response["data"]->Js.log
    response->Js.Promise.resolve
  })
}