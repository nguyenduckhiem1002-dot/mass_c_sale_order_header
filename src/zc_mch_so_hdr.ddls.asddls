@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change SO Header Rows'
@Metadata.allowExtensions: true
define projection view entity ZC_MCH_SO_HDR
  as projection on ZI_MCH_SO_HDR
{
  key Uuid,
  key UuidFile,
      SalesOrder, CustomerGroup, LcNumber, LcOpenDate,
      CommissionRate, ExportTrustContract, HasCustomerGroup, HasLcNumber,
      HasLcOpenDate, HasCommissionRate, HasExportTrustContract,
      @ObjectModel.text.element: ['OverallStatusText']
      MessageType,
      Criticality,
      @EndUserText.label: 'Status'
      @Semantics.text: true
      _OverallStatus.description as OverallStatusText,
      Message, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt,
      _ManageFile : redirected to parent ZC_MCH_SO_FILE,
      _OverallStatus
}
