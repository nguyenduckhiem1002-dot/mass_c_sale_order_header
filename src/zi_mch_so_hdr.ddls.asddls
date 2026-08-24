@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header'
define root view entity ZI_MCH_SO_HDR
  as select from ztb_mch_so_hdr
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
      message                 as Message,
      created_by              as CreatedBy,
      created_at              as CreatedAt,
      last_changed_by         as LastChangedBy,
      last_changed_at         as LastChangedAt
}
