type prisma = {
  testTable: Prisma.prismaModel,
  forms: Prisma.prismaModel,
  fields: Prisma.prismaModel,
  choices: Prisma.prismaModel,
  answers: Prisma.prismaModel,
}

let prisma = Prisma.prismaClient()
