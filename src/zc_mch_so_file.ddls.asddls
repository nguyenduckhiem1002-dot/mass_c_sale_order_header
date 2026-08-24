@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header - Files'
define projection view entity ZC_MCH_SO_FILE
  as projection on ZI_MCH_SO_FILE
{
  key Uuid,
      FileName,
      FileMimeType,
      Status,
      Message,
      CreatedBy,
      CreatedAt,
      LastChangedAt,
      _DataFile : redirected to composition child ZC_MCH_SO_HDR
}
