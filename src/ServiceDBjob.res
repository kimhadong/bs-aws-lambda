module Lambda = {
  open AwsLambda

  type object = {test: string}

  // choice type 질문의 항목 정보
  type choice = {
    id: string,
    label: string,
  }

  // 질문 데이터
  type field = {
    id: string,
    title: string,
    @as("type") field_type: string,
    ref: string,
    @optional properties: object,
    @optional choices: array<choice>,
  }

  // 폼 데이터
  type definition = {
    id: string,
    title: string,
    fields: array<field>    
  }

  // type answer = {
  //   type: string,
  //   @optional text: string,
  //   @optional choice: {label: string},
  //   @optional choice: {label: string},
  //   field: {
  //     "id": "g9hDtlYAWSHG",
  //     "type": "short_text",
  //     "ref": "030387c2-e02b-44b3-8d3c-f6991148d130"
  //   }
  // }

  // request 요청 데이터
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

//type prisma = {marketPrice: Prisma.prismaModel}
type prisma = {
  testTable: Prisma.prismaModel,
  forms: Prisma.prismaModel,
  fields: Prisma.prismaModel,
  choices: Prisma.prismaModel,
}

// connection 최소화를 위해 전역변수로 사용
let prisma = Prisma.prismaClient()

let truncate = date => {
  let where = {
    "where": {
      "date": date,
      "productCategoryCodeType": {
        "in": ["farm", "rice"],
      },
    },
  }
  prisma.testTable->Prisma.deleteMany(where)
}

let insertDb = datas => {
  let insertData = {
    "data": datas,
  }
  prisma.testTable->Prisma.createMany(insertData)
}

// let insertDb = datas => {
//   let insertData = {
//     "data": datas,
//   }
//   prisma.testTable->Prisma.createMany(insertData)
// }

let handler: Lambda.handler = (event, context, callback) => {
  open AwsLambda.Context
  open Lambda.Event

  // Prisma 를 썼을때 Event Loop 이 끝나지 않는 것으로 보임
  context->callbackWaitsForEmptyEventLoopSet(false)

  // Js.log(event->form_responseGet)
  // let test1 = event->form_responseGet
  // let test2 = event->form_responseGet->Belt.Option.getWithDefault(form_responseGet)
  // let test2 = event->fieldGet
  // let testt = switch event->form_responseGet {
  // | Soum(form_response) => expression
  // | pattern2 => expression
  // } 
  //->Belt.Option.flatMap(x => x.definition)
  //->Js.log
  // ->Belt.Option.map(x => {
  //   Js.log(x)
  //   x
  // })->Js.log

  
  let form_id =
    event->form_responseGet->Belt.Option.map(x => x.definition)->Belt.Option.map(x => x.id)
  let title =
    event->form_responseGet->Belt.Option.map(x => x.definition)->Belt.Option.map(x => x.title)
  let form_fields =
    event->form_responseGet->Belt.Option.map(x => x.definition)->Belt.Option.map(x => x.fields)->Belt.Option.getWithDefault([])

  form_fields->Belt.Array.map(x => {
    prisma.fields->Prisma.findUnique({
      "where": {
          "title": x.title
      },
    })
    |> Js.Promise.then_(field =>
      switch field->Js.Nullable.toOption {
      | Some(field) => field->Js.Promise.resolve
      | None => {

        prisma.fields->Prisma.create({
          "data":
            {
              "id": x.id,
              "form_id": form_id->Belt.Option.getWithDefault(""),
              "title": x.title,
              "field_type": x.field_type
            }
        })
        |> Js.Promise.then_(_ => {
          Js.log2("==================", x.field_type)
          // choice 문항 저장
          switch x.field_type {
          | "multiple_choice" | "picture_choice" => {
                  x.choices->Belt.Array.map(i => {
                    Js.log2("label", i.label)

                    prisma.choices->Prisma.findUnique({
                      "where": {
                          "label": i.label
                      },
                    })
                    |> Js.Promise.then_(choice =>
                      switch choice->Js.Nullable.toOption {
                      | Some(choice) => {
                        Js.log2("dlflfh???", choice)
                        choice->Js.Promise.resolve
                      }
                      | None => {
                        Js.log("none")
                        prisma.choices->Prisma.create({
                          "data":
                            {
                              "id": i.id,
                              "field_id": x.id,
                              "label": i.label
                            }
                        })
                        |> Js.Promise.then_(_ => {
                          Js.log("createeee")
                          callback(Js.Null.empty, "Success")
                          Js.Promise.resolve()
                        })
                        |> Js.Promise.catch(e => {
                          Js.log(e)
                          callback(Global.createError("fail")->Js.Null.return, "")

                          Js.Promise.resolve()
                        })
                      }
                      }
                    )

                  })
          }
          | _ => {
            Js.log("switch __________ ")
            callback(Js.Null.empty, "Success")
            [Js.Promise.resolve()]
          }
          }->Js.log

          callback(Js.Null.empty, "Success")
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(e => {
          Js.log(e)
          callback(Global.createError("fail")->Js.Null.return, "")

          Js.Promise.resolve()
        })

      }
      }
    )
  })->Js.log

  // Form의 대한 데이터 조회/저장
  prisma.forms->Prisma.findUnique({
    "where": {
      "id": form_id->Belt.Option.getWithDefault(""),
    },
  })
  |> Js.Promise.then_(form =>
    switch form->Js.Nullable.toOption {
    | Some(form) => {
        form->Js.Promise.resolve
    }
    | None =>
      prisma.forms->Prisma.createMany({
        "data": [
          {
            "id": form_id->Belt.Option.getWithDefault(""),
            "title": title->Belt.Option.getWithDefault(""),
          },
        ],
      })
      |> Js.Promise.then_(_ => {
        //form_fields->add_field(form_id)->Js.log
        callback(Js.Null.empty, "Success")
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(e => {
        Js.log(e)
        callback(Global.createError("fail")->Js.Null.return, "")
        Js.Promise.resolve()
      })
    }
  )
}
