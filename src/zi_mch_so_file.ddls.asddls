@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Mass Change SO Header Upload File'
define root view entity ZI_MCH_SO_FILE
  as select from ztb_mch_so_file
  association [0..1] to zi_req_sta_crud_poc_vh as _OverallStatus on $projection.Status = _OverallStatus.Status
  composition [0..*] of ZI_MCH_SO_HDR          as _DataFile
  association [0..1] to ZI_MCH_SO_HDR_CNT      as _Count         on $projection.Uuid = _Count.UuidFile
{
  key uuid                       as Uuid,

      file_name                  as FileName,
      file_mime_type             as FileMimeType,
      @Semantics.largeObject: {
      mimeType: 'FileMimeType',
      fileName: 'FileName',
      contentDispositionPreference: #ATTACHMENT
      }
      attachment                 as Attachment,
      @ObjectModel.text.element: ['OverallStatusText']
      status                     as Status,
      case status
        when 'E' then 1
        when 'X' then 1
        when 'J' then 2
        when 'P' then 2
        when 'D' then 3
        when 'S' then 3
        else 0
      end                        as Criticality,
      @EndUserText.label: 'Status'
      @Semantics.text: true
      _OverallStatus.description as OverallStatusText,
      message                    as Message,
      @Semantics.user.createdBy: true
      created_by                 as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at            as LastChangedAt,
      _Count.LineCount           as LineCount,
      _Count.SuccessCount        as SuccessCount,
      _DataFile,
      _OverallStatus,
      _Count
}
