@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header - Files'
@Metadata.allowExtensions: true
define projection view entity ZC_MCH_SO_FILE
  provider contract transactional_query
  as projection on ZI_MCH_SO_FILE
{
  key Uuid,
      FileName,
      FileMimeType,
      Attachment,
      Status,
      Criticality,
      OverallStatusText,
      Message,
      CreatedBy,
      CreatedAt,
      LastChangedAt,
      _DataFile : redirected to composition child ZC_MCH_SO_HDR
}
