CLASS zcl_mch_so_hdr_parser DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES BEGIN OF ty_row.
    TYPES cid TYPE string.
    TYPES sales_order TYPE string.
    TYPES customer_group TYPE string.
    TYPES lc_number TYPE string.
    TYPES lc_open_date TYPE d.
    TYPES commission_rate TYPE decfloat34.
    TYPES export_trust_contract TYPE string.
    TYPES has_customer_group TYPE abap_boolean.
    TYPES has_lc_number TYPE abap_boolean.
    TYPES has_lc_open_date TYPE abap_boolean.
    TYPES has_commission_rate TYPE abap_boolean.
    TYPES has_export_trust_contract TYPE abap_boolean.
    TYPES END OF ty_row.
    CLASS-METHODS parse IMPORTING iv_content TYPE xstring RETURNING VALUE(rt_rows) TYPE STANDARD TABLE OF ty_row
      RAISING zcx_mch_so_hdr.
  PRIVATE SECTION.
    CLASS-METHODS parse_date IMPORTING iv_value TYPE string RETURNING VALUE(rv_value) TYPE d.
    CLASS-METHODS parse_rate IMPORTING iv_value TYPE string RETURNING VALUE(rv_value) TYPE decfloat34.
ENDCLASS.

CLASS zcl_mch_so_hdr_parser IMPLEMENTATION.
  METHOD parse.
    TYPES BEGIN OF ty_input.
    TYPES sales_order TYPE string.
    TYPES customer_group TYPE string.
    TYPES lc_number TYPE string.
    TYPES lc_open_date TYPE string.
    TYPES commission_rate TYPE string.
    TYPES export_trust_contract TYPE string.
    TYPES END OF ty_input.
    DATA inputs TYPE STANDARD TABLE OF ty_input WITH EMPTY KEY.
    TRY.
        DATA(xlsx) = xco_cp_xlsx=>document->for_file_content( iv_file_content = iv_content )->read_access( ).
        DATA(sheet) = xlsx->get_workbook( )->worksheet->at_position( 1 ).
        DATA(pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
        DATA(execute) = sheet->select( pattern )->row_stream( )->operation->write_to( REF #( inputs ) ).
        execute->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
          )->if_xco_xlsx_ra_operation~execute( ).
      CATCH cx_root INTO DATA(error).
        RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = |Cannot read Excel: { error->get_text( ) }|.
    ENDTRY.
    DO 3 TIMES.
      IF inputs IS NOT INITIAL. DELETE inputs INDEX 1. ENDIF.
    ENDDO.
    LOOP AT inputs INTO DATA(input).
      IF input-sales_order IS INITIAL AND input-customer_group IS INITIAL AND input-lc_number IS INITIAL.
        CONTINUE.
      ENDIF.
      IF input-sales_order IS INITIAL.
        RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = |SO is mandatory at Excel row { sy-tabix + 3 }|.
      ENDIF.
      APPEND VALUE #( cid = |ROW_{ sy-tabix }| sales_order = input-sales_order
        customer_group = input-customer_group lc_number = input-lc_number
        lc_open_date = parse_date( input-lc_open_date ) commission_rate = parse_rate( input-commission_rate )
        export_trust_contract = input-export_trust_contract
        has_customer_group = xsdbool( input-customer_group IS NOT INITIAL )
        has_lc_number = xsdbool( input-lc_number IS NOT INITIAL )
        has_lc_open_date = xsdbool( input-lc_open_date IS NOT INITIAL )
        has_commission_rate = xsdbool( input-commission_rate IS NOT INITIAL )
        has_export_trust_contract = xsdbool( input-export_trust_contract IS NOT INITIAL ) ) TO rt_rows.
    ENDLOOP.
    IF rt_rows IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = 'Excel contains no Sales Order rows'.
    ENDIF.
  ENDMETHOD.

  METHOD parse_date.
    CHECK iv_value IS NOT INITIAL.
    IF iv_value CP '20####-##-##'.
      rv_value = iv_value+0(4) && iv_value+5(2) && iv_value+8(2).
    ELSEIF iv_value CO '0123456789'.
      rv_value = iv_value.
    ELSE.
      RAISE EXCEPTION TYPE zcx_mch_so_hdr EXPORTING text = |Invalid LC date: { iv_value }|.
    ENDIF.
  ENDMETHOD.

  METHOD parse_rate.
    DATA(value) = iv_value.
    CONDENSE value NO-GAPS.
    CHECK value IS NOT INITIAL.
    IF value CP '*%'.
      REPLACE ALL OCCURRENCES OF '%' IN value WITH ``.
      rv_value = CONV decfloat34( value ) / 100.
    ELSE.
      rv_value = CONV decfloat34( value ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
