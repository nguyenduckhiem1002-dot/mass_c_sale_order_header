@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header Upload File'
define root view entity ZI_MCH_SO_FILE
  as select from ztb_mch_so_file
  composition [0..*] of ZI_MCH_SO_HDR as _Rows
{
  key uuid as Uuid,
      file_name as FileName,
      file_mime_type as FileMimeType,
      status as Status,
      message as Message,
      created_by as CreatedBy,
      created_at as CreatedAt,
      last_changed_at as LastChangedAt,
      _Rows
}
