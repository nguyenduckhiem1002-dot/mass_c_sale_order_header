@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header - Consumption'
define projection view entity ZC_MCH_SO_HDR
  as projection on ZI_MCH_SO_HDR
{
  key Uuid, UuidFile, SalesOrder, CustomerGroup, LcNumber, LcOpenDate,
      CommissionRate, ExportTrustContract, HasCustomerGroup, HasLcNumber,
      HasLcOpenDate, HasCommissionRate, HasExportTrustContract, MessageType,
      Message, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt
}
