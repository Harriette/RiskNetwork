function risks_table_module_js(ns_prefix) {

  $("#" + ns_prefix + "risks_table").on("click", ".delete_btn", function() {
    Shiny.setInputValue(ns_prefix + "risk_id_to_delete", this.id, { priority: "event"});
    $(this).tooltip('hide');
  });

  $("#" + ns_prefix + "risks_table").on("click", ".edit_btn", function() {
    Shiny.setInputValue(ns_prefix + "risk_id_to_edit", this.id, { priority: "event"});
    $(this).tooltip('hide');
  });
}