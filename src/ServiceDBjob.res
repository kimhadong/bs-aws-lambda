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
  prisma->existsForm(event.eventId)
    |> Js.Promise.then_(x => {
      if x {
        event->Js.Promise.resolve
      } else {
        let createForm = prisma.forms->Prisma.create({
          "data": {
            "id": event.formResponse.formId,
            "title": event.formResponse.definition.title,
          },
        })
        
        let fieldLength = event.formResponse.definition.fields->Belt.Array.length
        let idArray = Belt.Array.make(fieldLength, event.formResponse.definition.id)
        let zippedArray = event.formResponse.definition.fields->Belt.Array.zip(idArray)

        let fields = zippedArray->Belt.Array.map(((x, formId)) =>
          {
            "id": x.id,
            "form_id": formId,
            "title": x.title,
            "field_type": x.fieldType,
          }
        )

        let createFields = prisma.fields->Prisma.createMany({"data": fields})

        let filteredFields = event.formResponse.definition.fields->Belt.Array.keep(x => {
          switch x.fieldType {
            | "multiple_choice" => true
            | _ => false
          }
        })

        let idArray = filteredFields->Belt.Array.map(x => x.id)
        let zippedArray = filteredFields->Belt.Array.zip(idArray)
        let choices = zippedArray->Belt.Array.map(((x, fieldId)) => {
          x.choices->Belt.Array.map(choice => {
            {
              "id": choice.id,
              "field_id": fieldId,
              "label": choice.label
            }
          })
        })->Belt.Array.concatMany
        
        let createChoices = prisma.choices->Prisma.createMany({"data": choices})

        prisma->Prisma.transaction([createForm, createFields, createChoices])
      }
    })
}

let createAnswer = (event: Typeform.requestData) => {
  let eventId = event.eventId

  let answers = event.formResponse.answers->Belt.Array.map(x => {
    {
      "event_id": eventId,
      "field_id": x.field.id,
      "answer_type": x.answerType
    }
  })
  prisma.answers->Prisma.createMany({"data": answers})
}

let handler: Lambda.handler = (event, context, _callback) => {
  open AwsLambda.Context

  // 1. find or create form
  event->findOrCreateForm->Js.log

  // 2. create answers
  event->createAnswer->Js.log

  context->callbackWaitsForEmptyEventLoopSet(false)

  "asdf"->Js.log->Js.Promise.resolve
}
