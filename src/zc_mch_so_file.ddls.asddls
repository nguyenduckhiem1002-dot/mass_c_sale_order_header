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
      @ObjectModel.text.element: ['OverallStatusText']
      Status,
      Criticality,
      @EndUserText.label: 'Status'
      @Semantics.text: true
      _OverallStatus.description as OverallStatusText,
      Message,
      CreatedBy,
      CreatedAt,
      LastChangedAt,
      _DataFile : redirected to composition child ZC_MCH_SO_HDR,
      _OverallStatus
}
