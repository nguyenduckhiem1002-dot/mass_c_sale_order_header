CLASS zcl_mch_so_hdr_update DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_row,
             sales_order TYPE c LENGTH 10,
             customer_group TYPE c LENGTH 2,
             lc_number TYPE string,
             lc_open_date TYPE d,
             commission_rate TYPE decfloat34,
             export_trust_contract TYPE string,
             has_customer_group TYPE abap_boolean,
             has_lc_number TYPE abap_boolean,
             has_lc_open_date TYPE abap_boolean,
             has_commission_rate TYPE abap_boolean,
             has_export_trust_contract TYPE abap_boolean,
           END OF ty_row.
    METHODS update
      IMPORTING is_row TYPE ty_row
      RETURNING VALUE(rv_message) TYPE string.
  PRIVATE SECTION.
    METHODS update_customer_group IMPORTING is_row TYPE ty_row RETURNING VALUE(rv_message) TYPE string.
    METHODS update_text IMPORTING iv_sales_order TYPE c iv_text_id TYPE c iv_text TYPE string
                        RETURNING VALUE(rv_message) TYPE string.
ENDCLASS.

CLASS zcl_mch_so_hdr_update IMPLEMENTATION.
  METHOD update.
    IF is_row-has_customer_group = abap_true.
      rv_message = update_customer_group( is_row ).
      IF rv_message IS NOT INITIAL. RETURN. ENDIF.
    ENDIF.
    DATA(texts) = VALUE string_table(
      ( COND #( WHEN is_row-has_lc_number = abap_true THEN |Z013={ is_row-lc_number }| ELSE `` ) )
      ( COND #( WHEN is_row-has_lc_open_date = abap_true THEN |Z014={ is_row-lc_open_date DATE = ISO }| ELSE `` ) )
      ( COND #( WHEN is_row-has_commission_rate = abap_true THEN |Z015={ is_row-commission_rate }| ELSE `` ) )
      ( COND #( WHEN is_row-has_export_trust_contract = abap_true THEN |Z011={ is_row-export_trust_contract }| ELSE `` ) ) ).
    LOOP AT texts INTO DATA(text).
      CHECK text IS NOT INITIAL.
      SPLIT text AT `=` INTO DATA(text_id) DATA(text_value).
      rv_message = update_text( iv_sales_order = is_row-sales_order iv_text_id = text_id iv_text = text_value ).
      IF rv_message IS NOT INITIAL. RETURN. ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD update_customer_group.
    " Replace this seam with the released Sales Order API or the approved Tier-3 wrapper.
  ENDMETHOD.
  METHOD update_text.
    " Replace this seam with the released Sales Order text API or approved wrapper.
  ENDMETHOD.
ENDCLASS.
