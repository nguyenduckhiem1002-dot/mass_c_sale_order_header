CLASS lhc_managefile DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ManageFile RESULT result.
    METHODS uploadExcel FOR MODIFY IMPORTING keys FOR ACTION ManageFile~uploadExcel.
    METHODS postConfirm FOR MODIFY IMPORTING keys FOR ACTION ManageFile~PostConfirm RESULT result.
    METHODS setStatusOpen FOR DETERMINE ON MODIFY IMPORTING keys FOR ManageFile~setStatusOpen.
    METHODS validateFile FOR VALIDATE ON SAVE IMPORTING keys FOR ManageFile~validateFile.
ENDCLASS.

CLASS lhc_managefile IMPLEMENTATION.
  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
    result-%action-PostConfirm = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD uploadExcel.
    READ TABLE keys ASSIGNING FIELD-SYMBOL(<key>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF <key>-%param-filecontent IS INITIAL.
      APPEND VALUE #( %cid = <key>-%cid %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error text = `Excel content is mandatory` ) )
        TO reported-managefile.
      RETURN.
    ENDIF.

    TRY.
        DATA(rows) = zcl_mch_so_hdr_parser=>parse( <key>-%param-filecontent ).
      CATCH zcx_mch_so_hdr INTO DATA(error).
        APPEND VALUE #( %cid = <key>-%cid %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error->text ) )
          TO reported-managefile.
        RETURN.
    ENDTRY.

    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY ManageFile
        CREATE FIELDS ( FileName FileMimeType Attachment Status )
        WITH VALUE #( ( %cid = <key>-%cid FileName = <key>-%param-filename
                        FileMimeType = <key>-%param-mimetype
                        Attachment = <key>-%param-filecontent Status = 'M' ) )
      ENTITY ManageFile
        CREATE BY \_DataFile
        FIELDS ( SalesOrder CustomerGroup LcNumber LcOpenDate CommissionRate ExportTrustContract
                 HasCustomerGroup HasLcNumber HasLcOpenDate HasCommissionRate HasExportTrustContract )
        WITH VALUE #( ( %cid_ref = <key>-%cid
          %target = VALUE #( FOR row IN rows
            ( %cid = row-cid SalesOrder = row-sales_order CustomerGroup = row-customer_group
              LcNumber = row-lc_number LcOpenDate = row-lc_open_date CommissionRate = row-commission_rate
              ExportTrustContract = row-export_trust_contract HasCustomerGroup = row-has_customer_group
              HasLcNumber = row-has_lc_number HasLcOpenDate = row-has_lc_open_date
              HasCommissionRate = row-has_commission_rate
              HasExportTrustContract = row-has_export_trust_contract ) ) ) )
      FAILED DATA(create_failed)
      REPORTED DATA(create_reported).

    APPEND LINES OF create_failed-managefile TO failed-managefile.
    APPEND LINES OF create_failed-datafile TO failed-datafile.
    APPEND LINES OF create_reported-managefile TO reported-managefile.
    APPEND LINES OF create_reported-datafile TO reported-datafile.
  ENDMETHOD.

  METHOD postConfirm.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY ManageFile BY \_DataFile ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE
      ENTITY DataFile UPDATE FIELDS ( MessageType Message )
      WITH VALUE #( FOR row IN rows
        ( %tky = row-%tky MessageType = 'J' Message = `Scheduled for background processing`
          %control-MessageType = if_abap_behv=>mk-on %control-Message = if_abap_behv=>mk-on ) )
      FAILED failed REPORTED reported.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY ManageFile
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(files).
    result = VALUE #( FOR file IN files ( %tky = file-%tky %param = file ) ).
  ENDMETHOD.

  METHOD setStatusOpen.
    MODIFY ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY ManageFile
      UPDATE FIELDS ( Status ) WITH VALUE #( FOR key IN keys
        ( %tky = key-%tky Status = 'M' %control-Status = if_abap_behv=>mk-on ) ).
  ENDMETHOD.

  METHOD validateFile.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY ManageFile
      FIELDS ( FileName ) WITH CORRESPONDING #( keys ) RESULT DATA(files).
    LOOP AT files INTO DATA(file) WHERE FileName IS INITIAL.
      APPEND VALUE #( %tky = file-%tky ) TO failed-managefile.
      APPEND VALUE #( %tky = file-%tky %element-FileName = if_abap_behv=>mk-on
        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
          text = `Excel file name is mandatory` ) ) TO reported-managefile.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_mch_so_file DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_mch_so_file IMPLEMENTATION.
  METHOD save_modified.
    READ TABLE update-datafile ASSIGNING FIELD-SYMBOL(<row>)
      WITH KEY MessageType = 'J'.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(start_timestamp).
    TRY.
        cl_apj_rt_api=>schedule_job(
          EXPORTING
            iv_job_template_name = 'ZAJT_MCH_SO_HEADER'
            iv_job_text = |Mass Change SO Header { start_timestamp TIMESTAMP = ISO }|
            is_start_info = VALUE #( timestamp = cl_abap_tstmp=>add(
              tstmp = start_timestamp secs = 1 ) )
            is_end_info = VALUE #( type = 'NUM' max_iterations = 1 )
            is_scheduling_info = VALUE #( periodic_value = 1 test_mode = abap_false timezone = 'UTC' )
            it_job_parameter_value = VALUE #( (
              name = 'HDR_ID'
              t_value = VALUE #( ( sign = 'I' option = 'EQ' low = <row>-UuidFile ) ) ) ) ).
      CATCH cx_apj_rt INTO DATA(error).
        APPEND VALUE #( Uuid = <row>-Uuid UuidFile = <row>-UuidFile
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
            text = error->get_longtext( ) ) ) TO reported-datafile.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_datafile DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateRow FOR VALIDATE ON SAVE IMPORTING keys FOR DataFile~validateRow.
ENDCLASS.

CLASS lhc_datafile IMPLEMENTATION.
  METHOD validateRow.
    READ ENTITIES OF zi_mch_so_file IN LOCAL MODE ENTITY DataFile
      FIELDS ( SalesOrder CustomerGroup LcNumber LcOpenDate CommissionRate ExportTrustContract )
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    IF rows IS INITIAL.
      RETURN.
    ENDIF.
    SELECT FROM I_SalesOrder WITH PRIVILEGED ACCESS FIELDS SalesOrder
      FOR ALL ENTRIES IN @rows WHERE SalesOrder = @rows-SalesOrder
      INTO TABLE @DATA(existing_sales_orders).
    LOOP AT rows INTO DATA(row).
      IF row-SalesOrder IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-datafile.
        APPEND VALUE #( %tky = row-%tky %element-SalesOrder = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
            text = `Sales Order is mandatory` ) ) TO reported-datafile.
        CONTINUE.
      ENDIF.
      IF NOT line_exists( existing_sales_orders[ SalesOrder = row-SalesOrder ] ).
        APPEND VALUE #( %tky = row-%tky ) TO failed-datafile.
        APPEND VALUE #( %tky = row-%tky %element-SalesOrder = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
            text = |Sales Order { row-SalesOrder } does not exist| ) ) TO reported-datafile.
      ENDIF.
      IF row-CustomerGroup IS INITIAL AND row-LcNumber IS INITIAL AND row-LcOpenDate IS INITIAL
         AND row-CommissionRate IS INITIAL AND row-ExportTrustContract IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-datafile.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = `At least one header field must be supplied` ) ) TO reported-datafile.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
