SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spJP_PNP_OrderText_JSON]
	@OrderId uniqueidentifier,
	@TextVersion int
AS
BEGIN
	Declare @MediaChannelArray ParamArrayNvarcharMax 
	
	Insert into @MediaChannelArray
	
	--Select DISTINCT CONCAT('"', MC.long_name, '"') From Order_Row ORow WITH(NOLOCK)
	Select DISTINCT  MV.long_name From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Value MV WITH(NOLOCK) ON MV.metadata_value_id = OTM.metadata_value_id
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Title'

	Declare @MediaChannelList nvarchar(max)
	Select @MediaChannelList = COALESCE(@MediaChannelList + ' %% ' + Parameter, Parameter) 
	From @MediaChannelArray





	Declare @LegacyCouncil nvarchar(255) = (Select TOP 1  MV.long_name From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Value MV WITH(NOLOCK) ON MV.metadata_value_id = OTM.metadata_value_id
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Legacy Council')
	Declare @PNPCategory nvarchar(255) = (Select TOP 1  MV.reference_code From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Value MV WITH(NOLOCK) ON MV.metadata_value_id = OTM.metadata_value_id
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Category')
	Declare @NoticeTitle nvarchar(max) = (Select TOP 1  OTM.string_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'NoticeTitle')


	Declare @NoticeBodyCopyraw nvarchar(max) = (Select TOP 1 OTM.text_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Body copy')

	Declare @NoticeFirstPararaw nvarchar(max) = (Select TOP 1 OTM.text_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice First Paragraph')

	Declare @NoticeBodyCopy nvarchar(max) = (Select TOP 1 CONCAT('<p>',Replace(OTM.text_data, Char(10), 'CARRIAGE_RETURN'),'</p>') From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Body copy')
	Declare @NoticeFirstPara nvarchar(max) = (Select TOP 1 CONCAT('<p>','<strong>', Replace(OTM.text_data, Char(10), 'CARRIAGE_RETURN'),'</strong>','</p>') From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice First Paragraph')
	Declare @NoticePostcode nvarchar(max) = (Select TOP 1  OTM.string_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Postcode List'
													AND Replace(OTM.string_data, ' ', '') <> 'NotApplicable')
	Declare @NoticeOutcode nvarchar(max) = (Select TOP 1  OTM.string_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Outcode List'
													AND Replace(OTM.string_data, ' ', '') <> 'NotApplicable'
													AND Replace(OTM.string_data, ' ', '') <> 'N/A')
	Declare @PNPStartDate datetime = (Select TOP 1  OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Publisher Start Date')
	Declare @PNPEndDate datetime = (Select TOP 1 OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'PNP Publisher End Date')
	Declare @NoticeFeedbackStartDate datetime = (Select TOP 1 OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Feedback Start Date')
	Declare @NoticeFeedbackEndDate datetime = (Select TOP 1 OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Feedback End Date')
	Declare @NoticeEffectiveStartDate datetime = (Select TOP 1 OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Effective Start Date')
	Declare @NoticeEffectiveEndDate datetime = (Select TOP 1 OTM.date_data From Order_Text_Metadata OTM WITH(NOLOCK)
													INNER JOIN Metadata_Type MT WITH(NOLOCK) ON MT.metadata_type_id = OTm.metadata_type_id
													Where OTM.order_id = @OrderId
													AND OTM.text_version = @TextVersion
													AND MT.long_name = 'Notice Effective End Date')

	Declare @NoticeBody2 nvarchar(max) = (Select CONCAT( @NoticeFirstPara, @NoticeBodyCopy ) )
	Declare @NoticeBodyWebsite nvarchar(max)
	Declare @NoticeBody nvarchar(max) =  (Select CONCAT( @NoticeFirstPara, @NoticeBodyCopy ) )

	Declare @NoticeBodyRaw nvarchar(max) = (Select CONCAT( @NoticeFirstPararaw, @NoticeBodyCopyRaw ) )
	set  @NoticeBodyWebsite = @NoticeBody2 




DECLARE
    @counter    INT = 1,
    @max        INT = 0

-- Declare a variable of type TABLE. It will be used as a temporary table.
DECLARE @myTable TABLE (
    [Id]        int identity,
    website   nvarchar(max)
)

-- Insert your required data in the variable of type TABLE
INSERT INTO @myTable
SELECT distinct Thelink 
FROM dbo.[fnJP_GetWebsiteFromText](@NoticeBodyRaw) 

-- Initialize the @max variable. We'll use thie variable in the next WHILE loop.
SELECT @max = COUNT(ID) FROM @myTable


-- Loop 
WHILE @counter <= @max
BEGIN

	Declare @website nvarchar(max) = (    SELECT website
    FROM @myTable
    WHERE Id = @counter)
		Declare @WebsiteCR nvarchar(max)



	Declare @CRW nvarchar(max), @CR1W nvarchar(max), @CR2W nvarchar(max)
	set @CRW = 'CARRIAGE_RETURN' +@WebsiteCR + 'CARRIAGE_RETURN'
	set @CR1W = 'CARRIAGE_RETURN'+@WebsiteCR 
	set @CR2W =  @WebsiteCR+'CARRIAGE_RETURN'

	
	
	If @NoticeBody2 like '%' + @CRW + '%' set @WebsiteCR = @CRW
	Else If @NoticeBody2 like '%' + @CR1W + '%' set @WebsiteCR = @CR1W
	Else If @NoticeBody2 like '%' + @CR2W + '%' set @WebsiteCR = @CR2W
	Else set @WebsiteCR = @website



set @NoticeBodyWebsite = replace  ((select @NoticeBody2) ,(select @WebsiteCR), '</p><p><a href="' + (select @website) +  '" target="_blank "rel="noopener">' + (select @website) + '</a></p><p>')
set @NoticeBody2 = @NoticeBodyWebsite 

    SET @counter = @counter + 1
END
	
	SET @NoticeBody = @NoticeBody2
    set @counter     = 1
    set @max         = 0


-- Declare a variable of type TABLE. It will be used as a temporary table.
DECLARE @myTableEmail TABLE (
    [Id]        int identity,
    Email   nvarchar(max)
)



-- Insert your required data in the variable of type TABLE
INSERT INTO @myTableEmail
SELECT DISTINCT Thelink 
FROM dbo.[fnJP_GetEmailFromText](@NoticeBodyRaw) 

-- Initialize the @max variable. We'll use thie variable in the next WHILE loop.
SELECT @max = COUNT(ID) FROM @myTableEmail


-- Loop 
WHILE @counter <= @max
BEGIN

	Declare @Email nvarchar(max) = (    SELECT Email
    FROM @myTableEmail
    WHERE Id = @counter)
	Declare @EmailCR nvarchar(max)



	Declare @CR nvarchar(max), @CR1 nvarchar(max), @CR2 nvarchar(max)
	set @CR = 'CARRIAGE_RETURN' +@Email + 'CARRIAGE_RETURN'
	set @CR1 = 'CARRIAGE_RETURN'+@Email 
	set @CR2 =  @Email+'CARRIAGE_RETURN'

	
	
	If @NoticeBodyWebsite like '%' + @CR + '%' set @EmailCR = @CR
	Else If @NoticeBodyWebsite like '%' + @CR1 + '%' set @EmailCR = @CR1
	Else If @NoticeBodyWebsite like '%' + @CR2 + '%' set @EmailCR = @CR2
	Else set @EmailCR = @Email
	

set @NoticeBody = replace  ((select @NoticeBodyWebsite) ,(select @EmailCR), '</p><p><a href="mailto:' + (select @Email) +  '" target="_blank "rel="noopener">' + (select @email) + '</a></p><p>')

set  @NoticeBodyWebsite = @NoticeBody 

    SET @counter = @counter + 1
End

	Declare @Xml xml

	If Len(@NoticeOutcode) > 0
	BEGIN
		Set @Xml = (Select 
					@MediaChannelList 'PublisherPrintTitle',
					Case When @TextVersion > 1 Then
						CONCAT(ORec.urn_text, '_V', @TextVersion) 
					Else
						ORec.urn_text
					End 'PublisherNoticeURN',
					@LegacyCouncil 'NoticeOriginatorName',
					@PNPCategory 'NoticeCategory',
					@NoticeTitle 'NoticeSummaryTitle',
					@NoticeBody 'NoticeBodyCopy',
					(Select item From dbo.fnGS_SplitString(Replace(@NoticeOutcode, ' ', ''), ',') FOR XML PATH(''), type) 'NoticeWideAreaOutcode',
					CONVERT(nvarchar(255), @PNPStartDate, 23) 'PNPPublishStartDate',
					CONVERT(nvarchar(255), @PNPEndDate, 23) 'PNPPublishEndDate',
					CONVERT(nvarchar(255), @NoticeFeedbackStartDate, 23) 'NoticeFeedbackStartDate',
					CONVERT(nvarchar(255), @NoticeFeedbackEndDate, 23) 'NoticeFeedbackEndDate',
					CONVERT(nvarchar(255), @NoticeEffectiveStartDate, 23) 'NoticeEffectiveStartDate',
					CONVERT(nvarchar(255), @NoticeEffectiveEndDate, 23) 'NoticeEffectiveEndDate'
				FROM Order_Record ORec WITH(NOLOCK) 
				INNER JOIN Order_Text OT WITH(NOLOCK) ON OT.order_id = ORec.order_id
				WHERE ORec.order_id = @OrderId
				AND OT.text_version = @TextVersion
				FOR XML PATH(''), root ('Root')
			)
	END
	ELSE
	BEGIN
		Set @Xml = (Select 
					@MediaChannelList 'PublisherPrintTitle',
					Case When @TextVersion > 1 Then
						CONCAT(ORec.urn_text, '_V', @TextVersion) 
					Else
						ORec.urn_text
					End 'PublisherNoticeURN',
					@LegacyCouncil 'NoticeOriginatorName',
					@PNPCategory 'NoticeCategory',
					@NoticeTitle 'NoticeSummaryTitle',
					@NoticeBody 'NoticeBodyCopy',
					(Select item From dbo.fnGS_SplitString(Replace(@NoticePostcode, ' ', ''), ',') FOR XML PATH(''), type) 'NoticeTargetLocationPcode',
					CONVERT(nvarchar(255), @PNPStartDate, 23) 'PNPPublishStartDate',
					CONVERT(nvarchar(255), @PNPEndDate, 23) 'PNPPublishEndDate',
					CONVERT(nvarchar(255), @NoticeFeedbackStartDate, 23) 'NoticeFeedbackStartDate',
					CONVERT(nvarchar(255), @NoticeFeedbackEndDate, 23) 'NoticeFeedbackEndDate',
					CONVERT(nvarchar(255), @NoticeEffectiveStartDate, 23) 'NoticeEffectiveStartDate',
					CONVERT(nvarchar(255), @NoticeEffectiveEndDate, 23) 'NoticeEffectiveEndDate'
				FROM Order_Record ORec WITH(NOLOCK) 
				INNER JOIN Order_Text OT WITH(NOLOCK) ON OT.order_id = ORec.order_id
				WHERE ORec.order_id = @OrderId
				AND OT.text_version = @TextVersion
				FOR XML PATH(''), root ('Root')
			)
	END

	


	Declare @json nvarchar(max) = Replace(cast(@Xml as nvarchar(max)), '<PublisherPrintTitle>', '<PublisherPrintTitle json:Array=''true'' xmlns:json=''http://james.newtonking.com/projects/json''>')
	Set @json = Replace(@json, '<NoticeTargetLocationPcode>', '<NoticeTargetLocationPcode json:Array=''true'' xmlns:json=''http://james.newtonking.com/projects/json''>')
	Set @json = Replace(@json, '<NoticeWideAreaOutcode>', '<NoticeWideAreaOutcode json:Array=''true'' xmlns:json=''http://james.newtonking.com/projects/json''>')
	Set @json = Replace(@json, '<Root>', '<Root json:Array=''true'' xmlns:json=''http://james.newtonking.com/projects/json''>')
	Set @json = dbo.XmlToJson(@json, 1)
	Set @json = Replace(@json, '{"item":[', '')
	Set @json = Replace(@json, ']}]', ']')
	Set @json = Replace(@json, '"NoticeTargetLocationPcode":[{"item":', '"NoticeTargetLocationPcode":[')
	Set @json = Replace(@json, '"NoticeWideAreaOutcode":[{"item":', '"NoticeWideAreaOutcode":[')
	Set @json = Replace(@json, '}],"PNPPublishStartDate"', '],"PNPPublishStartDate"')
	Set @json = Replace(@json, ' %% ', '", "')
	Set @json = Replace(@json, 'CARRIAGE_RETURN', '<br>')

	If Left(@json, 1) <> '['
	BEGIN
		Set @json = CONCAT('[', @json, ']')
	END

	Insert into PNP_Audit
	Select 'spJP_PNP_OrderText_JSON', @json, @OrderId, @TextVersion, GetUTCDate()

	Select @json
END


/*

	exec [spJP_PNP_OrderText_JSON] '96603a4f-63c4-4940-8cf2-694860f2d77c', 1

	Select * From PNP_Audit
	Order by 5 desc

	exec spGS_GetTaskFieldTextVersionValues '96603a4f-63c4-4940-8cf2-694860f2d77c', 1

*/

GO
