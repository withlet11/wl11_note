#lang racket

;; ============================================================
;; Constants
;; ============================================================

(define (make-description t) `("description" ,t))
(define (make-variables . lst) `("placeholders" ,@lst))

(define (set-variable name
                      #:type [t #f]
                      #:format [f #f]
                      #:isCustomDateFormat [b #f])
  `(,name ,@(if t `(("type" ,t)) '())
          ,@(if f `(("format" ,f)) '())
          ,@(if b `(("isCustomDateFormat" "true")) '())))


;; ============================================================
;; Data
;; ============================================================
;; Instructions:
;; - The default language is "en". Specify other languages using
;;   codes such as "ja-rJP".
;; - Use "*" to mark strings that should not be translated.
;;   These strings are included only in the default file and are
;;   marked with translatable="false".
;; - Specify the output directories for localized files in
;;   `lang-list`.
;; - Specify the strings in `value-list`.
;; - Specify additional attributes after the string.

(define lang-list '((en "../lib/l10n/app_en.arb")
                    (ja "../lib/l10n/app_ja.arb")
                    (hu "../lib/l10n/app_hu.arb")
                    (fr "../lib/l10n/app_fr.arb")
                    (zh "../lib/l10n/app_zh.arb")))

(define value-list
  `(("addTag"
     ((en "Add tag")
      (ja "タグを追加")
      (hu "Címke hozzáadása")
      (fr "Ajouter une étiquette")
      (zh "添加标签")))
    ("appTitle"
     ((en "WL11note")
      (ja "WL11note")
      (hu "WL11note")
      (fr "WL11note")
      (zh "WL11note")))
    ("appearance"
     ((en "Appearance")
      (ja "外観")
      (hu "Megjelenés")
      (fr "Apparence")
      (zh "外观")))
    ("backTooltip"
     ((en "Back")
      (ja "戻る")
      (hu "Vissza")
      (fr "Retour")
      (zh "返回")))
    ("backToNotesTooltip"
     ((en "Back to notes")
      (ja "ノート一覧に戻る")
      (hu "Vissza a jegyzetekhez")
      (fr "Retour aux notes")
      (zh "返回笔记列表")))
    ("blockquoteTooltip"
     ((en "Blockquote")
      (ja "引用ブロック")
      (hu "Idézetblokk")
      (fr "Citation")
      (zh "引用块")))
    ("boldTooltip"
     ((en "Bold (Ctrl+B)")
      (ja "太字 (Ctrl+B)")
      (hu "Félkövér (Ctrl+B)")
      (fr "Gras (Ctrl+B)")
      (zh "粗体 (Ctrl+B)")))
    ("bulletedListTooltip"
     ((en "Bulleted list (Ctrl+Shift+8)")
      (ja "箇条書き (Ctrl+Shift+8)")
      (hu "Felsorolás (Ctrl+Shift+8)")
      (fr "Liste à puces (Ctrl+Shift+8)")
      (zh "项目符号列表 (Ctrl+Shift+8)")))
    ("cancel"
     ((en "Cancel")
      (ja "キャンセル")
      (hu "Mégse")
      (fr "Annuler")
      (zh "取消")))
    ("clear"
     ((en "Clear")
      (ja "消去")
      (hu "Törlés")
      (fr "Effacer")
      (zh "清除")))
    ("clearFilters"
     ((en "Clear filters")
      (ja "フィルターを解除")
      (hu "Szűrők törlése")
      (fr "Effacer les filtres")
      (zh "清除筛选条件")))
    ("clearSearchTooltip"
     ((en "Clear search")
      (ja "検索をクリア")
      (hu "Keresés törlése")
      (fr "Effacer la recherche")
      (zh "清除搜索")))
    ("clearTrashTooltip"
     ((en "Clear Trash")
      (ja "ゴミ箱を空にする")
      (hu "Kuka ürítése")
      (fr "Vider la corbeille")
      (zh "清空回收站")))
    ("close"
     ((en "Close")
      (ja "閉じる")
      (hu "Bezárás")
      (fr "Fermer")
      (zh "关闭")))
    ("codeBlockTooltip"
     ((en "Code block")
      (ja "コードブロック")
      (hu "Kódblokk")
      (fr "Bloc de code")
      (zh "代码块")))
    ("couldNotDeleteNote"
     ((en "Could not delete note.")
      (ja "ノートを削除できませんでした。")
      (hu "A jegyzetet nem sikerült törölni.")
      (fr "Impossible de supprimer la note.")
      (zh "无法删除笔记。")))
    ("couldNotRestoreNote"
     ((en "Could not restore note.")
      (ja "ノートを復元できませんでした。")
      (hu "A jegyzetet nem sikerült visszaállítani.")
      (fr "Impossible de restaurer la note.")
      (zh "无法恢复笔记。")))
    ("createNewTag"
     ((en "Create a new tag")
      (ja "新しいタグを作成")
      (hu "Új címke létrehozása")
      (fr "Créer une nouvelle étiquette")
      (zh "创建新标签")))
    ("createNoteToGetStarted"
     ((en "Create a note to get started.")
      (ja "最初のノートを作成しましょう。")
      (hu "Hozzon létre egy jegyzetet a kezdéshez.")
      (fr "Créez une note pour commencer.")
      (zh "创建一条笔记以开始使用。")))
    ("createAndAdd"
     ((en "Create and add")
      (ja "作成して追加")
      (hu "Létrehozás és hozzáadás")
      (fr "Créer et ajouter")
      (zh "创建并添加")))
    ("createdAscending"
     ((en "Created date (oldest first)")
      (ja "作成日時（古い順）")
      (hu "Létrehozás dátuma (legrégebbi elöl)")
      (fr "Date de création (plus ancienne d’abord)")
      (zh "创建时间（最旧优先）")))
    ("createdDescending"
     ((en "Created date (newest first)")
      (ja "作成日時（新しい順）")
      (hu "Létrehozás dátuma (legújabb elöl)")
      (fr "Date de création (plus récente d’abord)")
      (zh "创建时间（最新优先）")))
    ("dark"
     ((en "Dark")
      (ja "ダーク")
      (hu "Sötét")
      (fr "Sombre")
      (zh "深色")))
    ("delete"
     ((en "Delete")
      (ja "削除")
      (hu "Törlés")
      (fr "Supprimer")
      (zh "删除")))
    ("deleteForever"
     ((en "Delete forever")
      (ja "完全に削除")
      (hu "Végleges törlés")
      (fr "Supprimer définitivement")
      (zh "永久删除")))
    ("deletePermanently"
     ((en "Delete permanently")
      (ja "完全に削除する")
      (hu "Végleges törlés")
      (fr "Supprimer définitivement")
      (zh "永久删除")))
    ("deletePermanentlyTooltip"
     ((en "Delete permanently")
      (ja "完全に削除する")
      (hu "Végleges törlés")
      (fr "Supprimer définitivement")
      (zh "永久删除")))
    ("deleteTagTooltip"
     ((en "Delete tag")
      (ja "タグの削除")
      (hu "Címke törlése")
      (fr "Supprimer l’étiquette")
      (zh "删除标签")))
    ("edit"
     ((en "Edit")
      (ja "編集")
      (hu "Szerkesztés")
      (fr "Modifier")
      (zh "编辑")))
    ("enterTagNameHint"
     ((en "Enter tag name")
      (ja "タグ名を入力")
      (hu "Adja meg a címke nevét")
      (fr "Saisissez le nom de l’étiquette")
      (zh "输入标签名称")))
    ("existingTags"
     ((en "Existing tags")
      (ja "既存のタグ")
      (hu "Meglévő címkék")
      (fr "Étiquettes existantes")
      (zh "现有标签")))
    ("exportAsMarkdownTooltip"
     ((en "Export as Markdown")
      (ja "Markdown形式でエクスポート")
      (hu "Exportálás Markdown formátumban")
      (fr "Exporter au format Markdown")
      (zh "导出为 Markdown")))
    ("horizontalRuleTooltip"
     ((en "Horizontal rule")
      (ja "水平線")
      (hu "Vízszintes elválasztó vonal")
      (fr "Ligne horizontale")
      (zh "水平分隔线")))
    ("initializationFailed"
     ((en "Initialization failed")
      (ja "初期化に失敗しました")
      (hu "Az inicializálás nem sikerült")
      (fr "Échec de l’initialisation")
      (zh "初始化失败")))
    ("inlineCodeTooltip"
     ((en "Inline code (Ctrl+Shift+C)")
      (ja "インラインコード (Ctrl+Shift+C)")
      (hu "Sorközi kód (Ctrl+Shift+C)")
      (fr "Code en ligne (Ctrl+Shift+C)")
      (zh "行内代码 (Ctrl+Shift+C)")))
    ("italicTooltip"
     ((en "Italic (Ctrl+I)")
      (ja "斜体 (Ctrl+I)")
      (hu "Dőlt (Ctrl+I)")
      (fr "Italique (Ctrl+I)")
      (zh "斜体 (Ctrl+I)")))
    ("language"
     ((en "Language")
      (ja "言語")
      (hu "Nyelv")
      (fr "Langue")
      (zh "语言")))
    ("large"
     ((en "Large")
      (ja "大")
      (hu "Nagy")
      (fr "Grande")
      (zh "大")))
    ("light"
     ((en "Light")
      (ja "ライト")
      (hu "Világos")
      (fr "Clair")
      (zh "浅色")))
    ("linkTooltip"
     ((en "Link (Ctrl+K)")
      (ja "リンク (Ctrl+K)")
      (hu "Hivatkozás (Ctrl+K)")
      (fr "Lien (Ctrl+K)")
      (zh "链接 (Ctrl+K)")))
    ("manageTagsTooltip"
     ((en "Manage tags")
      (ja "タグの管理")
      (hu "Címkék kezelése")
      (fr "Gérer les étiquettes")
      (zh "管理标签")))
    ("medium"
     ((en "Medium")
      (ja "中")
      (hu "Közepes")
      (fr "Moyenne")
      (zh "中")))
    ("menuTooltip"
     ((en "Menu")
      (ja "メニュー")
      (hu "Menü")
      (fr "Menu")
      (zh "菜单")))
    ("moveToTrashTooltip"
     ((en "Move to Trash")
      (ja "ゴミ箱に移動")
      (hu "Áthelyezés a kukába")
      (fr "Déplacer dans la corbeille")
      (zh "移至回收站")))
    ("nameAscending"
     ((en "Note name (A–Z)")
      (ja "ノート名（A–Z）")
      (hu "Jegyzet neve (A–Z)")
      (fr "Nom de la note (A–Z)")
      (zh "笔记名称（A–Z）")))
    ("nameDescending"
     ((en "Note name (Z–A)")
      (ja "ノート名（Z–A）")
      (hu "Jegyzet neve (Z–A)")
      (fr "Nom de la note (Z–A)")
      (zh "笔记名称（Z–A）")))
    ("newNoteTooltip"
     ((en "New note")
      (ja "新規ノート")
      (hu "Új jegyzet")
      (fr "Nouvelle note")
      (zh "新建笔记")))
    ("noMatchingNotes"
     ((en "No matching notes")
      (ja "該当するノートがありません")
      (hu "Nincs találat")
      (fr "Aucune note correspondante")
      (zh "没有匹配的笔记")))
    ("noNoteSelected"
     ((en "No note selected")
      (ja "ノートが選択されていません")
      (hu "Nincs jegyzet kiválasztva")
      (fr "Aucune note sélectionnée")
      (zh "未选择笔记")))
    ("noNotesYet"
     ((en "No notes yet")
      (ja "ノートがありません")
      (hu "Még nincsenek jegyzetek")
      (fr "Aucune note pour le moment")
      (zh "还没有笔记")))
    ("noTagsCreatedYet"
     ((en "No tags created yet.")
      (ja "タグはまだありません。")
      (hu "Még nincsenek címkék.")
      (fr "Aucune étiquette pour le moment.")
      (zh "还没有创建标签。")))
    ("noteDeleteError"
     ((en "Could not delete note: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "ノートを削除できませんでした: {error}")
      (hu "A jegyzetet nem sikerült törölni: {error}")
      (fr "Impossible de supprimer la note : {error}")
      (zh "无法删除笔记：{error}")))
    ("noteDeletedDate"
     ((en "Deleted {date}"
          ,(make-variables
            (set-variable "date" #:type "String")))
      (ja "{date}に削除")
      (hu "Törlés dátuma: {date}")
      (fr "Supprimée le {date}")
      (zh "删除日期：{date}")))
    ("noteExportError"
     ((en "Could not export note: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "ノートをエクスポートできませんでした: {error}")
      (hu "A jegyzet exportálása nem sikerült: {error}")
      (fr "Impossible d’exporter la note : {error}")
      (zh "无法导出笔记：{error}")))
    ("noteExporteNotification"
     ((en "Note exported successfully.")
      (ja "ノートをエクスポートしました。")
      (hu "A jegyzet exportálása sikeres.")
      (fr "La note a été exportée avec succès.")
      (zh "笔记已成功导出。")))
    ("noteMoveToTrashNotification"
     ((en "\\\"{title}\\\" moved to Trash"
          ,(make-variables
            (set-variable "title" #:type "String")))
      (ja "「{title}」をゴミ箱に移動しました")
      (hu "A(z) „{title}” a kukába került")
      (fr "« {title} » a été déplacée dans la corbeille")
      (zh "已将“{title}”移至回收站")))
    ("notePermanentDeleteConfirmation"
     ((en "Delete \\\"{title}\\\" permanently? This action cannot be undone."
          ,(make-variables
            (set-variable "title" #:type "String")))
      (ja "「{title}」を完全に削除しますか？この操作は取り消せません。")
      (hu "Véglegesen törli a(z) „{title}” jegyzetet? Ez a művelet nem vonható vissza.")
      (fr "Supprimer définitivement « {title} » ? Cette action est irréversible.")
      (zh "确定永久删除笔记“{title}”吗？此操作无法撤销。")))
    ("notePermanentDeleteConfirmationTitle"
     ((en "Delete permanently?")
      (ja "完全に削除しますか？")
      (hu "Véglegesen törli?")
      (fr "Supprimer définitivement ?")
      (zh "确定永久删除吗？")))
    ("notePermanentDeleteError"
     ((en "Could not delete note permanently: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "ノートを完全に削除できませんでした: {error}")
      (hu "A jegyzet végleges törlése nem sikerült: {error}")
      (fr "Impossible de supprimer définitivement la note : {error}")
      (zh "无法永久删除笔记：{error}")))
    ("noteRestoreError"
     ((en "Could not restore note: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "ノートを復元できませんでした: {error}")
      (hu "A jegyzetet nem sikerült visszaállítani: {error}")
      (fr "Impossible de restaurer la note : {error}")
      (zh "无法恢复笔记：{error}")))
    ("numberedListTooltip"
     ((en "Numbered list (Ctrl+Shift+7)")
      (ja "番号付きリスト (Ctrl+Shift+7)")
      (hu "Számozott lista (Ctrl+Shift+7)")
      (fr "Liste numérotée (Ctrl+Shift+7)")
      (zh "编号列表 (Ctrl+Shift+7)")))
    ("preview"
     ((en "Preview")
      (ja "プレビュー")
      (hu "Előnézet")
      (fr "Aperçu")
      (zh "预览")))
    ("rename"
     ((en "Rename")
      (ja "名前を変更")
      (hu "Átnevezés")
      (fr "Renommer")
      (zh "重命名")))
    ("renameTagTooltip"
     ((en "Rename tag")
      (ja "タグ名を変更")
      (hu "Címke átnevezése")
      (fr "Renommer l’étiquette")
      (zh "重命名标签")))
    ("restoreNoteTooltip"
     ((en "Restore note")
      (ja "ノートの復元")
      (hu "Jegyzet visszaállítása")
      (fr "Restaurer la note")
      (zh "恢复笔记")))
    ("restoredNotification"
     ((en "\\\"{title}\\\" restored"
          ,(make-variables
            (set-variable "title" #:type "String")))
      (ja "「{title}」を復元しました")
      (hu "A(z) „{title}” visszaállítva")
      (fr "« {title} » a été restaurée")
      (zh "已恢复“{title}”")))
    ("retry"
     ((en "Retry")
      (ja "再試行")
      (hu "Újra")
      (fr "Réessayer")
      (zh "重试")))
    ("saveFailedRetryTooltip"
     ((en "Save failed. Retry")
      (ja "保存に失敗しました。再試行")
      (hu "A mentés nem sikerült. Újrapróbálás")
      (fr "Échec de l’enregistrement. Réessayer")
      (zh "保存失败。重试")))
    ("searchNotes"
     ((en "Search notes")
      (ja "ノートを検索")
      (hu "Jegyzetek keresése")
      (fr "Rechercher des notes")
      (zh "搜索笔记")))
    ("selectNoteOrCreateNewOne"
     ((en "Select a note or create a new one.")
      (ja "ノートを選択するか、新しいノートを作成してください。")
      (hu "Válasszon ki egy jegyzetet, vagy hozzon létre újat.")
      (fr "Sélectionnez une note ou créez-en une nouvelle.")
      (zh "请选择一条笔记或创建新笔记。")))
    ("settings"
     ((en "Settings")
      (ja "設定")
      (hu "Beállítások")
      (fr "Paramètres")
      (zh "设置")))
    ("small"
     ((en "Small")
      (ja "小")
      (hu "Kicsi")
      (fr "Petite")
      (zh "小")))
    ("sortNotesTooltip"
     ((en "Sort notes")
      (ja "ノートの並べ替え")
      (hu "Jegyzetek rendezése")
      (fr "Trier les notes")
      (zh "笔记排序")))
    ("startWritingHint"
     ((en "Start writing...")
      (ja "入力を開始...")
      (hu "Kezdjen el írni...")
      (fr "Commencez à écrire...")
      (zh "开始输入...")))
    ("strikethroughTooltip"
     ((en "Strikethrough (Ctrl+Shift+X)")
      (ja "取り消し線 (Ctrl+Shift+X)")
      (hu "Áthúzott (Ctrl+Shift+X)")
      (fr "Barré (Ctrl+Shift+X)")
      (zh "删除线 (Ctrl+Shift+X)")))
    ("systemDefault"
     ((en "System default")
      (ja "システム設定に従う")
      (hu "Rendszer alapértelmezése")
      (fr "Par défaut du système")
      (zh "系统默认")))
    ("tagAddError"
     ((en "Could not add tag: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "タグを追加できませんでした: {error}")
      (hu "A címkét nem sikerült hozzáadni: {error}")
      (fr "Impossible d’ajouter l’étiquette : {error}")
      (zh "无法添加标签：{error}")))
    ("tagDeleteConfirmationDescription"
     ((en "Delete \\\"{tagName}\\\"? It will be removed from all notes."
          ,(make-variables
            (set-variable "tagName" #:type "String")))
      (ja "「{tagName}」を消しますか？すべてのノートから削除されます。")
      (hu "Törli a(z) „{tagName}” címkét? A címke az összes jegyzetből el lesz távolítva.")
      (fr "Supprimer l’étiquette « {tagName} » ? Elle sera supprimée de toutes les notes.")
      (zh "确定删除标签“{tagName}”吗？该标签将从所有笔记中移除。")))
    ("tagDeleteConfirmationTitle"
     ((en "Delete tag?")
      (ja "タグを削除しますか？")
      (hu "Törli a címkét?")
      (fr "Supprimer l’étiquette ?")
      (zh "确定删除标签吗？")))
    ("tagDeleteError"
     ((en "Could not delete tag: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "タグを削除できませんでした：{error}")
      (hu "A címkét nem sikerült törölni: {error}")
      (fr "Impossible de supprimer l’étiquette : {error}")
      (zh "无法删除标签：{error}")))
    ("tagManageDialogTitle"
     ((en "Manage tags")
      (ja "タグの管理")
      (hu "Címkék kezelése")
      (fr "Gérer les étiquettes")
      (zh "管理标签")))
    ("tagName"
     ((en "Tag name")
      (ja "タグ名")
      (hu "Címke neve")
      (fr "Nom de l’étiquette")
      (zh "标签名称")))
    ("tagRenameDialogTitle"
     ((en "Rename tag")
      (ja "タグ名を変更")
      (hu "Címke átnevezése")
      (fr "Renommer l’étiquette")
      (zh "重命名标签")))
    ("tagRenameError"
     ((en "Could not rename tag: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "タグ名を変更できませんでした：{error}")
      (hu "A címke nevét nem sikerült módosítani: {error}")
      (fr "Impossible de renommer l’étiquette : {error}")
      (zh "无法重命名标签：{error}")))
    ("textFormattingTooltip"
     ((en "Text formatting")
      (ja "テキスト書式")
      (hu "Szövegformázás")
      (fr "Mise en forme du texte")
      (zh "文本格式")))
    ("textSize"
     ((en "Text size")
      (ja "文字サイズ")
      (hu "Szövegméret")
      (fr "Taille du texte")
      (zh "文字大小")))
    ("trash"
     ((en "Trash")
      (ja "ゴミ箱")
      (hu "Kuka")
      (fr "Corbeille")
      (zh "回收站")))
    ("trashClearConfirmationDescription"
     ((en "Permanently delete {count, plural, zero {no notes} one {1 note} other {{count} notes}}? This action cannot be undone."
          ,(make-description "Count of notes that will be deleted permanently.")
          ,(make-variables
            (set-variable "count" #:type "int")))
      (ja "{count} 件のノートを完全に削除しますか？この操作は取り消せません。")
      (hu "Véglegesen töröl {count} jegyzetet? Ez a művelet nem vonható vissza.")
      (fr "Supprimer définitivement {count, plural, one {une note} other {{count} notes}} ? Cette action est irréversible.")
      (zh "确定永久删除 {count} 条笔记吗？此操作无法撤销。")))
    ("trashClearConfirmationTitle"
     ((en "Clear Trash?")
      (ja "ゴミ箱を空にしますか？")
      (hu "Kiüríti a kukát?")
      (fr "Vider la corbeille ?")
      (zh "确定清空回收站吗？")))
    ("trashClearError"
     ((en "Could not clear Trash: {error}"
          ,(make-variables
            (set-variable "error" #:type "String")))
      (ja "ゴミ箱を空にできませんでした: {error}")
      (hu "A kuka ürítése nem sikerült: {error}")
      (fr "Impossible de vider la corbeille : {error}")
      (zh "无法清空回收站：{error}")))
    ("trashClearNotification"
     ((en "{count, plural, zero {no notes} one {1 note} other {{count} notes}} permanently deleted"
          ,(make-description "Count of notes deleted permanently.")
          ,(make-variables
            (set-variable "count" #:type "int")))
      (ja "{count} 件のノートを完全に削除しました")
      (hu "{count} jegyzet véglegesen törölve")
      (fr "{count, plural, one {Une note a été supprimée définitivement} other {{count} notes ont été supprimées définitivement}}")
      (zh "已永久删除 {count} 条笔记")))
    ("trashIsEmpty"
     ((en "Trash is empty")
      (ja "ゴミ箱は空です")
      (hu "A kuka üres")
      (fr "La corbeille est vide")
      (zh "回收站为空")))
    ("tryDifferentSearchOrTagFilter"
     ((en "Try a different search or tag filter.")
      (ja "検索条件またはタグフィルターを変更してください。")
      (hu "Próbáljon más keresési feltételt vagy címkeszűrőt.")
      (fr "Essayez une autre recherche ou un autre filtre d’étiquettes.")
      (zh "请尝试更改搜索内容或标签筛选条件。")))
    ("undo"
     ((en "Undo")
      (ja "元に戻す")
      (hu "Visszavonás")
      (fr "Annuler")
      (zh "撤销")))
    ("updatedAscending"
     ((en "Updated date (oldest first)")
      (ja "更新日時（古い順）")
      (hu "Frissítés dátuma (legrégebbi elöl)")
      (fr "Date de modification (plus ancienne d’abord)")
      (zh "更新时间（最旧优先）")))
    ("updatedDescending"
     ((en "Updated date (newest first)")
      (ja "更新日時（新しい順）")
      (hu "Frissítés dátuma (legújabb elöl)")
      (fr "Date de modification (plus récente d’abord)")
      (zh "更新时间（最新优先）")))))


;; ============================================================
;; Processing
;; ============================================================
;; Usage:
;;   racket localize.rkt
;;
;; Run from the directory containing this file.
;;
;; Revision history:
;; - 2026-10-19: Initial version.

(define (create-xml-doc lst lang)
  `("{"
    ,(string-append "  \"@@locale\": \"" (symbol->string lang) "\",")
    ,@(flatten (entry->string (get-entries-with-lang lst lang) 1))
    "}"))

(define (get-entries-with-lang lst lang)
  (filter
   list?
   (map (lambda (entry)
          (let ([key (first entry)] [vals (second entry)])
            (cond [(assq lang vals)
                   => (lambda (val) (cons key (cdr val)))]
                  [else (error "missing localized strings" lang entry)])))
        lst)))

(define (entry->string entries idx)
  (add-delimiter-between
   (map (lambda (x)
          (let ([key (car x)] [content (cadr x)] [attrs (cddr x)])
            (if (null? attrs)
                (string-append (make-string (* 2 idx) #\space) "\""
                               key "\": \"" content "\"")
                `(,(string-append (make-string (* 2 idx) #\space)
                                  "\"" key "\": \"" content "\",")
                  ,(string-append (make-string (* 2 idx) #\space)
                                  "\"@" key "\": {")
                  ,(values->string attrs (add1 idx))
                  ,(string-append (make-string (* 2 idx) #\space)
                                  "}")))))
        entries)))

(define (values->string entries idx)
  (add-delimiter-between
   (map (lambda (x)
          (let ([key (car x)] [val (cdr x)])
            (cond [(list? (car val))
                   `(,(string-append (make-string (* 2 idx) #\space)
                                     "\"" key "\": {")
                     ,(values->string val (add1 idx))
                     ,(string-append (make-string (* 2 idx) #\space)
                                     "}"))]
                  [(string? (car val))
                   (string-append (make-string (* 2 idx) #\space)
                                  "\"" key "\": \"" (car val) "\"")]
                  [else (error "malform" x)])))
        entries)))

(define (add-delimiter-between lst)
  (foldr (lambda (x acc)
           (if (null? acc)
               (list x)
               (cons (add-delimiter-at-end x) acc)))
         '()
         lst))

(define (add-delimiter-at-end x)
  (if (string? x)
      (string-append x ",")
      (let ([r (reverse x)])
        (reverse (cons (add-delimiter-at-end (car r)) (cdr r))))))

(for-each (lambda (x)
            (let ([lang (first x)]
                  [path (second x)])
              (call-with-output-file (string->path path)
                (lambda (out)
                  (for-each (lambda (ln) (displayln ln out))
                            (create-xml-doc value-list lang)))
                #:exists 'replace)))
          lang-list)

(displayln "Completed!")
