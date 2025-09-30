DECLARE @publication_date DATETIME = '2025-08-01' ;

-- declare dev vars above this line
-- start this line and above is removed by code

SELECT
     orec.urn_text urnNumber
    ,@publication_date publicationDate
    ,mc.long_name title
    ,cc.long_name classification
    ,sc.long_name style
    ,ot.rtf_text  rtf
    ,ma.external_asset_id pdfPath
    ,ct.long_name componentType
    ,(
        SELECT otm.string_data
            FROM Order_Text_Metadata otm
                INNER JOIN Metadata_Type mt ON mt.metadata_type_id = otm.metadata_type_id
        WHERE otm.order_id = orec.order_id
            AND otm.text_version = orow.first_text_version
            AND mt.long_name = 'NoticeTitle'
     ) as noticeTitle
     ,
    (
        SELECT otm.text_data
            FROM Order_Text_Metadata otm
                INNER JOIN Metadata_Type mt ON mt.metadata_type_id = otm.metadata_type_id
        WHERE otm.order_id = orec.order_id
            AND otm.text_version = orow.first_text_version
            AND mt.long_name = 'Notice First Paragraph'
     ) as noticeFirstParagraph
     ,
    (
        SELECT otm.text_data
            FROM Order_Text_Metadata otm
                INNER JOIN Metadata_Type mt ON mt.metadata_type_id = otm.metadata_type_id
        WHERE otm.order_id = orec.order_id
            AND otm.text_version = orow.first_text_version
            AND mt.long_name = 'Notice Body copy'
     ) as noticeBodyCopy

FROM order_record orec
    INNER JOIN order_row orow ON orec.order_id = orow.order_id
    INNER JOIN order_insert oi ON oi.order_id = orow.order_id AND oi.order_row_id = orow.order_row_id
    INNER JOIN media_channel mc ON mc.media_channel_id = orow.media_channel_id
    INNER JOIN Media_Channel_Type mct ON mct.media_channel_type_id = mc.media_channel_type_id
    INNER JOIN Classification cc ON cc.classification_id = orow.classification_id
    INNER JOIN style sc ON sc.style_id = orow.style_id
    INNER JOIN Page_Group pg ON pg.pgroup_id = orow.pgroup_id
    LEFT JOIN order_text ot ON ot.order_id = orec.order_id AND ot.text_version = orow.first_text_version
    LEFT JOIN Component_Usage cu on cu.order_id = orow.order_id
    LEFT JOIN Component_Type ct on ct.component_type_id = cu.component_type_id
    LEFT JOIN Multimedia_Asset ma on ma.multimedia_asset_id = cu.multimedia_asset_id
WHERE 1 = 1
    AND pg.long_name = 'Public Notices'
    AND mct.long_name = 'Print'
    AND orec.first_insert_date = @publication_date
    AND NOT( orow.stop_date IS NOT NULL AND oi.insert_date >= orow.stop_date )
    AND ct.long_name = 'Output PDF'
ORDER BY
    title, urnNumber,classification,style
;