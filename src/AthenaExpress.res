type aws
@module
external awsSdk: aws = "aws-sdk"

type config

@obj
external makeConfig: (
  ~aws: aws=?,
  @optional ~s3: string=? /* optional format 's3://bucketname' */,
  @optional ~db: string=? /* optional */,
  @optional ~workgroup: string=? /* optional */,
  @optional ~formatJson: bool=? /* optional default=true */,
  @optional ~retry: int=? /* optional default=200 */,
  @optional ~getStats: bool=? /* optional default=false */,
  @optional ~ignoreEmpty: bool=? /* optional default=true */,
  @optional ~encryption: 'a=? /* optional */,
  @optional ~skipResults: bool=? /* optional default=false */,
  @optional ~waitForResults: bool=? /* optional default=true */,
  unit,
) => config = ""

type athenaExpress

@module("athena-express") @new
external createAthenaExpress: config => athenaExpress = "AthenaExpress"

@send external query: (athenaExpress, string) => Js.Promise.t<'a> = "query"
