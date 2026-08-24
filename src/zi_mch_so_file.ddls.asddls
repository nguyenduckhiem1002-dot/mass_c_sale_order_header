@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change Sales Order Header Upload File'
define root view entity ZI_MCH_SO_FILE
  as select from ztb_mch_so_file
  composition [0..*] of ZI_MCH_SO_HDR as _DataFile
{
  key uuid as Uuid,
      file_name as FileName,
      file_mime_type as FileMimeType,
      attachment as Attachment,
      status as Status,
      message as Message,
      @Semantics.user.createdBy: true
      created_by as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at as CreatedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
      _DataFile
}
