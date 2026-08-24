@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header'
define view entity ZI_MCH_SO_HDR
  as select from ztb_mch_so_hdr
  association [0..1] to zi_msg_sta_crud_poc_vh as _OverallStatus
    on $projection.MessageType = _OverallStatus.Status
  association to parent ZI_MCH_SO_FILE as _ManageFile
    on $projection.UuidFile = _ManageFile.Uuid
{
  key uuid                   as Uuid,
      uuid_file              as UuidFile,
      sales_order             as SalesOrder,
      customer_group          as CustomerGroup,
      lc_number               as LcNumber,
      lc_open_date            as LcOpenDate,
      commission_rate         as CommissionRate,
      export_trust_contract   as ExportTrustContract,
      has_customer_group     as HasCustomerGroup,
      has_lc_number          as HasLcNumber,
      has_lc_open_date       as HasLcOpenDate,
      has_commission_rate    as HasCommissionRate,
      has_export_trust_contract as HasExportTrustContract,
      message_type            as MessageType,
      case message_type
        when 'E' then 1
        when 'J' then 2
        when 'S' then 3
        else 0
      end                     as Criticality,
      message                 as Message,
      @Semantics.user.createdBy: true
      created_by              as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at              as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by         as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at         as LastChangedAt,
      _ManageFile,
      _OverallStatus
}
