/*
https://www.zotero.org/support/dev/client_coding/javascript_api

available things:
  item.getFilePath()
  item.isAttachment()

ZoteroPane.getSelectedItems()
Zotero.RecognizePDF.recognizeItems(attached)
Zotero.RecognizePDF.autoRecognizeItems(items)
*/

var items = ZoteroPane.getSelectedItems();
var attached = items.filter(function(i,n) { return i.isAttachment() })
Zotero.RecognizePDF.recognizeItems(attached)
