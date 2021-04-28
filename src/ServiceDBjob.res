
module Array = {
  let chunk = (arr, size) => {
    let arrSize = arr->Belt.Array.size
    let max = arrSize / size
    let max = max + (mod(arrSize, size) > 0 ? 1 : 0)
    if max == 1 {
      [arr]
    } else {
      Belt.Array.range(0, max - 1)->Belt.Array.map(i => {
        arr->Belt.Array.slice(~offset=i * size, ~len=size)
      })
    }
  }
}

module Lambda = {
  open AwsLambda

  type object = {
    test: string
  }

  type choice = {
    id: string,
    label: string
  }

  type field = {
    id: string,
    title: string,
    field_type: string,
    ref: string,
    @optional properties: object,
    @optional choices: choice
  }

  type definition = {
    id: string,
    title: string,
    fields: array<field>            
  }

  type form_response = {
    form_id: string,
    token: string,
    landed_at: string,
    submitted_at: string,
    definition: definition
  }
  

  module Event = {
    @deriving(abstract)
    type t = {
      @optional event_id: string,
      @optional event_type: string,
      @optional form_response: form_response
    }
  }

  type handler = handler<Event.t, Global.error, string>
}

//type prisma = {marketPrice: Prisma.prismaModel}
type prisma = {
  testTable: Prisma.prismaModel,
  form: Prisma.prismaModel
}

// connection 최소화를 위해 전역변수로 사용
let prisma = Prisma.prismaClient()

let addAthenaPartitions = (athenaExpress, dateStr) => {
  let re = Js.Re.fromStringWithFlags("-", ~flags="g")
  let s3Path = "s3://farmmorning-market-price/" ++ dateStr->Js.String2.replaceByRe(re, "/")

  let partition =
    [
      "PARTITION (",
      "date='" ++ dateStr ++ "'",
      ")",
      "LOCATION '" ++ s3Path ++ "/'",
    ]->Js.Array2.joinWith("")

  let qs = "ALTER TABLE market_price ADD " ++ partition

  athenaExpress->AthenaExpress.query(qs)
}

let process = (athenaExpress) => {
  let qs = "select * from test_table"
  Js.log("process==============")
  athenaExpress->AthenaExpress.query(qs)
    |> Js.Promise.then_(data => {
      Js.log2("==data:==", data)
      data["Items"]->Js.Promise.resolve
    })
}


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

let ignoreNanPrice = datas => {
  datas->Belt.Array.keep(d => d["price"] != "NaN")
}

let insertDb = datas => {
  let insertData = {
    "data": datas,
  }
  prisma.testTable->Prisma.createMany(insertData)
}

let handler: Lambda.handler = (event, context, callback) => {
  Js.log(event);
  
  open AwsLambda.Context
  open Lambda.Event

  // let athenaExpressConfig = AthenaExpress.makeConfig(
  //   ~aws=AthenaExpress.awsSdk,
  //   ~db=Env.athenaDBName,
  //   ~s3=Env.athenaS3Bucket,
  //   (),
  // )
  // let athenaExpress = AthenaExpress.createAthenaExpress(athenaExpressConfig)

  // Prisma 를 썼을때 Event Loop 이 끝나지 않는 것으로 보임
  context->callbackWaitsForEmptyEventLoopSet(false)
  
  //let date = event->form_responseGet
  
  Js.log2("event", event->event_idGet)
  Js.log2("event", event->event_typeGet)
  Js.log2("event", event->form_responseGet)

  // let aggregate = (date, callback) => {
  //   let a = athenaExpress->process    
  //   Js.log2("athenaExpress->process", a)
  //   let b = a |> Js.Promise.then_(_ => date->truncate)

  //   Js.Promise.all([a, b])
  //   |> Js.Promise.then_(v => v->Belt.Array.getExn(0)->Js.Promise.resolve)
  //   |> Js.Promise.then_(datas => {
  //     datas->Array.chunk(1000)
  //     ->Belt.Array.map(ds => ds->ignoreNanPrice)
  //     ->Belt.Array.map(ds => ds->insertDb)
  //     |> Js.Promise.all
  //     |> Js.Promise.then_(_ => {
  //       callback(Js.Null.empty, "Success")
  //       Js.Promise.resolve()
  //     })
  //     |> Js.Promise.catch(e => {
  //       Js.log(e)
  //       callback(Global.createError("fail")->Js.Null.return, "")
  //       Js.Promise.resolve()
  //     })
  //   })
  // }


  // athenaExpress->addAthenaPartitions(date)
  // |> Js.Promise.catch(e => {
  //   switch e {
  //   | exception e =>
  //     let optError = Js.Exn.asJsExn(e)
  //     switch optError {
  //     | Some(error) if Js.Exn.name(error) == Some("AlreadyExistsException") =>
  //       // 파티션이 이미 있는 경우 오류 무시하도록
  //       aggregate(date, callback)
  //     | _ => Js.Promise.resolve()
  //     }
  //   | _ => Js.Promise.resolve()
  //   }
  // })
  // |> Js.Promise.then_(_ => aggregate(date, callback))

    //insertDb
    let form_id = event->form_responseGet->Belt.Option.map(x => x.definition)->Belt.Option.map(x => x.id)
    let title = event->form_responseGet->Belt.Option.map(x => x.definition)->Belt.Option.map(x => x.title)

    Js.log2("==select form_id:====================", form_id)
    Js.log2("==select form_id:====================", form_id->Belt.Option.getWithDefault(""))
    
  
    prisma.form->Prisma.findUnique({
      "where": {
        "id": form_id->Belt.Option.getWithDefault("")
      }
    })
    |> Js.Promise.then_(form => 
      switch form->Js.Nullable.toOption {
      | Some(form) => form->Js.Promise.resolve
      | None => {
        Js.log("---------------")
        prisma.form->Prisma.createMany({
          "id": form_id->Belt.Option.getWithDefault(""),
          "title": title->Belt.Option.getWithDefault(""),
          "created_at": "2021-03-01"
        }) 
        |> Js.Promise.then_(_ => {
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
    // |> Js.Promise.then_(weatherUserResult =>
    //     switch weatherUserResult {
    //     | Some(weatherUserResult) => Js.Promise.resolve(weatherUserResult)
    //     | None => 
          
    //     }
    //   )

    // |> Js.Promise.then_(v => {
    //   v->Belt.Array.getExn(0)->Js.Promise.resolve
    // })
      // |> Js.Promise.catch(e => {
      //   switch e {
      //   | exception e =>
      //     let optError = Js.Exn.asJsExn(e)
      //     switch optError {
      //     | Some(error) if Js.Exn.name(error) == Some("AlreadyExistsException") =>
      //       // 파티션이 이미 있는 경우 오류 무시하도록
      //       // aggregate(date, callback)
      //       // |> Js.Promise.then_(v => v->Belt.Array.getExn(0)->Js.Promise.resolve)
      //       Js.Promise.resolve()
      //     | _ => Js.Promise.resolve()
      //     }
      //   | _ => Js.Promise.resolve()
      //   }
      // })
      
  
}