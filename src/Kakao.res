module Lambda = {
  open AwsLambda

  type object = {test: string}

  type choice = {
    id: string,
    label: string,
  }

  type field = {
    id: string,
    title: string,
    field_type: string,
    ref: string,
    @optional properties: object,
    @optional choices: choice,
  }

  type definition = {
    id: string,
    title: string,
    fields: array<field>,
  }

  type form_response = {
    form_id: string,
    token: string,
    landed_at: string,
    submitted_at: string,
    definition: definition,
  }

  module Event = {
    @deriving(abstract)
    type t = {
      @optional event_id: string,
      @optional event_type: string,
      @optional form_response: form_response,
    }
  }

  type handler = handler<Event.t, Global.error, string>
}

let parseEnvVar = (env, key) => {
  switch env->Js.Dict.get(key) {
  | None => `ENV ${key} IS REQUIRED`->Js.Exn.raiseError
  | Some(key) => key
  }
}

let handler: Lambda.handler = (_, _, _) => {
  // TODO: Option으로 처리 변경
  let env = Node.Process.process["env"]
  let apiURL = env->parseEnvVar("NHN_ALIMTALK_NHN_API_URL")
  let plusFriendID = env->parseEnvVar("NHN_ALIMTALK_NHN_PLUS_FRIEND_ID")
  let appKey = env->parseEnvVar("NHN_ALIMTALK_NHN_APP_KEY")
  let secretKey = env->parseEnvVar("NHN_ALIMTALK_NHN_SECRET_KEY")

  let url = apiURL ++ "/alimtalk/v1.5/appkeys/" ++ appKey ++ "/raw-messages"

  let buttons = [
    {
      "ordering": 1,
      "type": "AL",
      "name": `정보 입력하기`,
      "schemeIos": "http://farm.fmorning.com/lmi4gf",
      "schemeAndroid": "http://farm.fmorning.com/lmi4gf",
    },
    {
      "ordering": 2,
      "type": "AL",
      "name": `농자재 쿠폰 받기`,
      "schemeIos": "http://m.farmmorningstore.com/exec/front/newcoupon/IssueDownload?coupon_no=6068948950700000357&utm_campaign=farmstore&utm_source=kakaotalk&utm_medium=crm&utm_content=farmstore_alimtalk_welcome_0407",
      "schemeAndroid": "http://m.farmmorningstore.com/exec/front/newcoupon/IssueDownload?coupon_no=6068948950700000357&utm_campaign=farmstore&utm_source=kakaotalk&utm_medium=crm&utm_content=farmstore_alimtalk_welcome_0407",
    },
  ]
  let message = `안녕하세요. 전민규님
팜모닝 가입을 축하드립니다! 🎉

📍 전민규님의 작물과 농장 정보를 입력해주세요. 작물 별로, 병해충 별로 마음 편히 농사 지으실 수 있게 유용한 정보들을 전달해드리겠습니다. 

📍 또한 팜모닝 회원분들을 위해 농자재 상점 20% 할인 쿠폰을 전달드리고 있으니 지금 받아가세요! ❤️`

  let payload = {
    "plusFriendId": plusFriendID,
    "templateCode": "welcomeinfo",
    "recipientList": [
      {
        "recipientNo": "01095993116",
        "content": message,
        "buttons": buttons,
      },
    ],
  }
  let headers = Axios.Headers.fromObj({
    "Content-type": "application/json;charset=UTF-8",
    "X-Secret-Key": secretKey,
  })

  let config = Axios.makeConfig(~headers, ())

  let asdf = Axios.postDatac(url, payload, config) |> Js.Promise.then_(response => {
    response["data"]->Js.log
    response->Js.Promise.resolve
  })

  asdf->Js.log->Js.Promise.resolve
}
