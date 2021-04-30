open Context

module Lambda = {
  open AwsLambda

  module Event = {
    @deriving(abstract)
    type t = Typeform.requestData
  }

  type handler = handler<Event.t, Global.error, string>
}

let existsForm = (prisma, formId) => {
  prisma.forms->Prisma.findFirst({
    "where": {
      "id": formId,
    },
  }) |> Js.Promise.then_(x => x->Js.Nullable.toOption->Belt.Option.isSome->Js.Promise.resolve)
}

let findOrCreateForm = (event: Typeform.requestData) => {
  let createForm = (event: Typeform.requestData) =>
    prisma.forms->Prisma.create({
      "data": {
        "id": event.formResponse.formId,
        "title": event.formResponse.definition.title,
      },
    })
  let createFields = (fields, formId) => {
    let fieldLength = fields->Belt.Array.length
    let idArray = Belt.Array.make(fieldLength, formId)
    let zippedArray = fields->Belt.Array.zip(idArray)
    let fields = zippedArray->Belt.Array.map(((x: Typeform.field, formId)) => {
      {
        "id": x.id,
        "form_id": formId,
        "title": x.title,
        "field_type": x.fieldType,
      }
    })

    prisma.fields->Prisma.createMany({"data": fields})
  }

  let createChoices = (fields: array<Typeform.field>) => {
    let idArray = fields->Belt.Array.map(x => x.id)
    let zippedArray = fields->Belt.Array.zip(idArray)
    let choices =
      zippedArray
      ->Belt.Array.map(((x, fieldId)) => {
        x.choices->Belt.Array.map(choice => {
          {
            "id": choice.id,
            "field_id": fieldId,
            "label": choice.label,
          }
        })
      })
      ->Belt.Array.concatMany

    prisma.choices->Prisma.createMany({"data": choices})
  }

  prisma->existsForm(event.formResponse.formId)
    |> Js.Promise.then_(x => {
      if x {
        event->Js.Promise.resolve
      } else {
        let fields = event.formResponse.definition.fields
        let formId = event.formResponse.definition.id

        let createForm = event->createForm
        let createFields = fields->createFields(formId)

        let filterWords = ["multiple_choice"]->Belt.Set.String.fromArray
        let filteredFields =
          fields->Belt.Array.keep(x => filterWords->Belt.Set.String.has(x.fieldType))

        let createChoices = filteredFields->createChoices

        prisma->Prisma.transaction([createForm, createFields, createChoices])
      }
    })
}

let createAnswer = (event: Typeform.requestData) => {
  let eventId = event.eventId

  let answerToString = (eventId, x: Typeform.answer) => {
    let response = switch x.answerType {
    | "text" => x.text
    | "email" => x.email
    | "date" => x.date
    | "url" => x.url
    | "number" => x.number->Belt.Float.toString
    | "phone_number" => x.phoneNumber
    | "file_url" => x.fileUrl
    | "payment" =>
      Js.Dict.fromArray([
        ("amount", x.payment.amount->Js.Json.string),
        ("last4", x.payment.last4->Js.Json.string),
        ("name", x.payment.name->Js.Json.string),
        ("success", ""->Js.Json.string),
      ])
      ->Js.Json.object_
      ->Js.Json.stringify
    | "boolean" => x.boolean->Js.Json.boolean->Js.Json.stringify
    | "choice" =>
      Js.Dict.fromArray([("label", x.choice.label->Js.Json.string)])
      ->Js.Json.object_
      ->Js.Json.stringify
    | "choices" =>
      Js.Dict.fromArray([
        ("labels", x.choices.labels->Js.Json.stringArray),
        // ("other", x.choices.other->Js.Json.string),
      ])
      ->Js.Json.object_
      ->Js.Json.stringify
    | _ => ""
    }

    {
      "event_id": eventId,
      "field_id": x.field.id,
      "answer_type": x.answerType,
      "response": response,
    }
  }

  let answers = event.formResponse.answers->Belt.Array.map(answerToString(eventId))
  prisma.answers->Prisma.createMany({"data": answers})
}

let handler: Lambda.handler = (event, context, _callback) => {
  open AwsLambda.Context

  // 1. find or create form
  event->findOrCreateForm->Js.log

  // 2. create answers
  let asdf = event->createAnswer->Promise.Js.fromBsPromise->Promise.Js.map(x => x)
  asdf->Js.log

  // 3. kakao alimtalk send
  //Alimtalk.sendAlimtalk()->Js.log

  context->callbackWaitsForEmptyEventLoopSet(false)

  "asdf"->Js.log->Js.Promise.resolve
}
