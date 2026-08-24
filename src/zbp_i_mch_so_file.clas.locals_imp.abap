CLASS lhc_managefile DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS c_header_rows TYPE i VALUE 3.
    METHODS earlynumbering_create FOR NUMBERING IMPORTING entities FOR CREATE ManageFile.
    METHODS uploadExcel FOR MODIFY IMPORTING keys FOR ACTION ManageFile~uploadExcel.
    METHODS postConfirm FOR MODIFY IMPORTING keys FOR ACTION ManageFile~PostConfirm RESULT result.
    METHODS setStatusOpen FOR DETERMINE ON MODIFY IMPORTING keys FOR ManageFile~setStatusOpen.
    METHODS validateFile FOR VALIDATE ON SAVE IMPORTING keys FOR ManageFile~validateFile.
ENDCLASS.

CLASS lhc_managefile IMPLEMENTATION.
  METHOD earlynumbering_create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>) WHERE uuid IS INITIAL.
      TRY.
          <entity>-uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
          APPEND VALUE #( %cid = <entity>-%cid %key = <entity>-%key ) TO mapped-managefile.
        CATCH cx_uuid_error INTO DATA(error).
          APPEND VALUE #( %cid = <entity>-%cid %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error text = error->get_text( ) ) ) TO reported-managefile.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD uploadExcel.
    READ TABLE keys ASSIGNING FIELD-SYMBOL(<key>) INDEX 1.
    CHECK sy-subrc = 0 AND <key>-%param-filecontent IS NOT INITIAL.
    DATA lt_rows TYPE STANDARD TABLE OF zcl_mch_so_hdr_parser=>ty_row WITH EMPTY KEY.
    TRY.
        lt_rows = zcl_mch_so_hdr_parser=>parse( <key>-%param-filecontent ).
      CATCH zcx_mch_so_hdr INTO DATA(error).
        APPEND VALUE #( %cid = <key>-%cid %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error->text ) ) TO reported-managefile.
        RETURN.
    ENDTRY.
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY ManageFile CREATE FIELDS ( FileName FileMimeType Status )
      WITH VALUE #( ( %cid = <key>-%cid FileName = <key>-%param-filename
                      FileMimeType = <key>-%param-mimetype Status = 'M' ) )
      MAPPED DATA(mapped) FAILED DATA(failed) REPORTED DATA(reported).
    APPEND LINES OF reported-managefile TO reported-managefile.
    IF failed-managefile IS NOT INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mapped-managefile ASSIGNING FIELD-SYMBOL(<mapped>) INDEX 1.
    CHECK sy-subrc = 0.
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY ManageFile CREATE BY \_DataFile
      FIELDS ( SalesOrder CustomerGroup LcNumber LcOpenDate CommissionRate ExportTrustContract
               HasCustomerGroup HasLcNumber HasLcOpenDate HasCommissionRate HasExportTrustContract )
      WITH VALUE #( FOR row IN lt_rows
        ( %cid_ref = <key>-%cid
          %target = VALUE #( ( %cid = row-cid SalesOrder = row-sales_order
            CustomerGroup = row-customer_group LcNumber = row-lc_number LcOpenDate = row-lc_open_date
            CommissionRate = row-commission_rate ExportTrustContract = row-export_trust_contract
            HasCustomerGroup = row-has_customer_group HasLcNumber = row-has_lc_number
            HasLcOpenDate = row-has_lc_open_date HasCommissionRate = row-has_commission_rate
            HasExportTrustContract = row-has_export_trust_contract ) ) ) )
      MAPPED DATA(mapped_child) FAILED DATA(failed_child) REPORTED DATA(reported_child).
  ENDMETHOD.

  METHOD postConfirm.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY ManageFile BY \_DataFile ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    DATA api_rows TYPE zcl_call_api_ud_so_hdr=>tt_header.
    LOOP AT rows INTO DATA(row).
      APPEND VALUE #( Uuid = row-Uuid SalesOrder = row-SalesOrder CustomerGroup = row-CustomerGroup
        LcNumber = row-LcNumber LcOpenDate = row-LcOpenDate CommissionRate = row-CommissionRate
        ExportTrustContract = row-ExportTrustContract HasCustomerGroup = row-HasCustomerGroup
        HasLcNumber = row-HasLcNumber HasLcOpenDate = row-HasLcOpenDate
        HasCommissionRate = row-HasCommissionRate HasExportTrustContract = row-HasExportTrustContract ) TO api_rows.
    ENDLOOP.
    zcl_call_api_ud_so_hdr=>update_header( CHANGING ct_data = api_rows ).
    LOOP AT api_rows ASSIGNING FIELD-SYMBOL(<api_row>).
      READ TABLE rows ASSIGNING FIELD-SYMBOL(<row>) WITH KEY Uuid = <api_row>-Uuid.
      IF sy-subrc = 0.
        <row>-MessageType = <api_row>-MessageType.
        <row>-Message = <api_row>-Message.
      ENDIF.
    ENDLOOP.
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY DataFile UPDATE FIELDS ( MessageType Message )
      WITH VALUE #( FOR row IN rows ( %tky = row-%tky MessageType = row-message_type Message = row-message
        %control-MessageType = if_abap_behv=>mk-on %control-Message = if_abap_behv=>mk-on ) )
      FAILED failed REPORTED reported.
    result = VALUE #( FOR key IN keys ( %tky = key-%tky %param = key ) ).
  ENDMETHOD.

  METHOD setStatusOpen.
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY ManageFile
      UPDATE FIELDS ( Status ) WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'M'
        %control-Status = if_abap_behv=>mk-on ) ).
  ENDMETHOD.

  METHOD validateFile.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY ManageFile
      FIELDS ( FileName ) WITH CORRESPONDING #( keys ) RESULT DATA(files).
    LOOP AT files INTO DATA(file) WHERE FileName IS INITIAL.
      APPEND VALUE #( %tky = file-%tky ) TO failed-managefile.
      APPEND VALUE #( %tky = file-%tky %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error text = 'Excel file name is mandatory' ) ) TO reported-managefile.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
