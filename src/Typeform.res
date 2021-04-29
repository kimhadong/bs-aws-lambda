type answerField = {
  id: string,
  answerFieldType: string,
}

type payment = {amount: string, last4: string, name: string, success: bool}
type choice = { label: string }
type choices = {labels: array<string>, @optional other: string}

type answer = {
  @as("type") answerType: string,
  @optional text: string,
  @optional email: string,
  @optional date: string,
  @optional url: string,
  @optional number: float,
  @as("file_url") @optional fileUrl: string,
  @optional payment: payment,
  @optional boolean: bool,
  @optional choice: choice,
  @optional choices: choices,
  field: answerField,
}

type fieldChoice = {id: string, label: string}

type field = {
  id: string,
  title: string,
  @as("type") fieldType: string,
  ref: string,
  @as("allow_multiple_selections") allowMultipleSections: bool,
  @as("allow_other_choice") allowOtherChoice: bool,
  @as("choices") @optional choices: array<fieldChoice>
}

type definition = {
  id: string,
  title: string,
  fields: array<field>,
}

type calculated = {score: int}

type formResponse = {
  @as("form_id") formId: string,
  token: string,
  @as("submittedAt") submittedAt: string,
  @as("landedAt") landedAt: string,
  calculated: calculated,
  definition: definition,
  answers: array<answer>
}

type requestData = {
  @as("event_id") eventId: string,
  @as("event_type") eventType: string,
  @as("form_response") formResponse: formResponse,
}
