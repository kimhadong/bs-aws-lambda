@module("@prisma/client") @new
external prismaClient: unit => 'prisma = "PrismaClient"

type prismaModel

@send external findFirst: (prismaModel, 'args) => Js.Promise.t<Js.Nullable.t<'ret>> = "findFirst"

@send external create: (prismaModel, 'args) => Js.Promise.t<'ret> = "create"

@send external deleteMany: (prismaModel, 'args) => Js.Promise.t<'ret> = "deleteMany"

@send external findUnique: (prismaModel, 'args) => Js.Promise.t<Js.Nullable.t<'ret>> = "findUnique"

@send external findMany: (prismaModel, 'args) => Js.Promise.t<'ret> = "findMany"

@send external createMany: (prismaModel, 'args) => Js.Promise.t<'ret> = "createMany"

@send external transaction: (_, array<'prismaQuery>) => Js.Promise.t<'ret> = "$transaction"