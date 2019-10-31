#include 'totvs.ch'
#include "FWBrowse.ch"
#Include 'FWMVCDef.ch'


user function ORTO001()

  Local oBrowse

  oBrowse := BrowseDef()

  oBrowse:Activate()

return


static function Browsedef()

  Local oBrowse

  oBrowse := FWMBrowse():New()
  oBrowse:SetAlias( "Z10" )
  oBrowse:SetDescription( "Kits" )
  oBrowse:setMenuDef('FUNAKI_ORTO001')

return oBrowse


static function MenuDef()

  Local aRotina := {}

  ADD OPTION aRotina Title "Visualizar" Action 'VIEWDEF.FUNAKI_ORTO001' OPERATION MODEL_OPERATION_VIEW   ACCESS 0
  ADD OPTION aRotina Title "Incluir"    Action 'VIEWDEF.FUNAKI_ORTO001' OPERATION MODEL_OPERATION_INSERT ACCESS 0
  ADD OPTION aRotina Title "Alterar"    Action 'VIEWDEF.FUNAKI_ORTO001' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
  ADD OPTION aRotina Title "Excluir"    Action 'VIEWDEF.FUNAKI_ORTO001' OPERATION MODEL_OPERATION_DELETE ACCESS 0
  ADD OPTION aRotina Title "Copiar"    Action 'VIEWDEF.FUNAKI_ORTO001' OPERATION OP_COPIA ACCESS 0
  ADD OPTION aRotina Title "ExecAuto"    Action 'u_ORTO01Exec' OPERATION MODEL_OPERATION_VIEW ACCESS 0

return aRotina


static function ModelDef()

  Local oStructHeader := FWFormStruct(1, "Z10") // ORTO - KIT INSTRUMENTAL CABEC
  Local oStructItems := FWFormStruct(1, "Z11") // ORTO - KIT INSTRUMENTAL ITENS

  Local oModel := MPFormModel():New('_ORTO001')

  oStructHeader:addField("Carregar grid","Clique para grid com as informações da estrutura de produtos", 'BOTAO', 'BT',1,0,{|| loadItems(oModel) }, { || .T. })
  oStructHeader:addTrigger( 'Z10_PRODUT', 'Z10_DESPRO', {||.T.}, {|model| Posicione("SB1",1,xFilial("SB1")+ model:getValue("Z10_PRODUT"), "B1_DESC") })
  oStructItems:addTrigger( 'Z11_PRODUT', 'Z11_DESPRO', {||.T.}, {|model| Posicione("SB1",1,xFilial("SB1")+ model:getValue("Z11_PRODUT"), "B1_DESC") })

  oStructHeader:SetProperty('Z10_PRODUT' ,MODEL_FIELD_WHEN , {|| ! oModel:IsCopy() })

  oModel:AddFields('HEADER',, oStructHeader)
  oModel:AddGrid('ITEMS', 'HEADER', oStructItems)

  oModel:SetRelation('ITEMS', { { 'Z11_FILIAL', 'xFilial( "Z11" )' } , { 'Z11_CODIGO', 'Z10_CODIGO' } } , Z11->(IndexKey(1)) )

  oModel:SetDescription("Kit de procedimentos")

  oModel:SetPrimaryKey( { "Z10_FILIAL", "Z10_CODIGO" } )

  oModel:GetModel('ITEMS'):setUniqueLine( { 'Z11_PRODUT' } )
  oModel:GetModel("HEADER"):SetFldNoCopy( { 'Z10_CODIGO' } )

  oModel:SetActivate( {|oModel| OnActivate(oModel)})

return oModel


static function OnActivate(oModel)

  Local nOperation := oModel:GetOperation()
  Local oHeader :=oModel:GetModel('HEADER')
  Local oItems :=oModel:GetModel('ITEMS')

  if nOperation != MODEL_OPERATION_INSERT
    oHeader:GetStruct():SetProperty("Z10_CODIGO", MODEL_FIELD_NOUPD, .T.)
    oHeader:GetStruct():SetProperty("Z10_PRODUT", MODEL_FIELD_NOUPD, .T.)
  endif

  if oModel:isCopy()
    oItems:ClearData(.T.)
  endif

return

static function ViewDef()

  Local oStructHeader := FWFormStruct(2, "Z10") // ORTO - KIT INSTRUMENTAL CABEC
  Local oStructItems := FWFormStruct(2, "Z11") // ORTO - KIT INSTRUMENTAL ITENS

  Local oModel := ModelDef()
  Local oView  := FWFormView():New()

  oStructHeader:AddField('BOTAO','10',"Carregar grid","Clique para Carregar o GRID",, 'BT',,,,,,"ACS")

  oStructItems:removeField('Z11_CODIGO')

  oView:SetModel( oModel )


  oView:AddField('viewHEADER', oStructHeader, 'HEADER')
  oView:AddGrid('viewITEMS', oStructItems, 'ITEMS')


  oView:CreateHorizontalBox('Line01' , 20 )
  oView:CreateHorizontalBox('Line02' , 80 )

  oView:SetOwnerView('viewHEADER', 'Line01' )
  oView:SetOwnerView('viewITEMS', 'Line02' )

  oView:EnableTitleView('viewITEMS', 'Produtos' )

  oView:SetViewProperty("viewITEMS" , "GRIDSEEK", {.T.})

return oView


static function loadItems(oModel)

  Local oHeader := oModel:getModel('HEADER')
  Local oItems := oModel:getModel('ITEMS')

  Local cProduct := oHeader:getValue("Z10_PRODUT")
  Local cKey

  SG1->( dbSetOrder(1) )
  SG1->( dbSeek( cKey := xFilial("SG1") + cProduct ) )

  while ! SG1->( eof() ) .and. SG1->G1_FILIAL + SG1->G1_COD == cKey

    if ! oItems:seekLine({{"Z11_PRODUT",  SG1->G1_COMP }}, .T.) .and. ! oItems:isEmpty()
      oItems:goLine(oItems:addLine())
    endif

    if oItems:IsDeleted()
      oItems:UnDeleteLine()
    endif

    oItems:setValue('Z11_PRODUT', SG1->G1_COMP)
    oItems:setValue('Z11_QTDPAD', SG1->G1_QUANT)

    SG1->( dbSkip() )
  enddo

  oItems:goLine(1)

return .T.



user function ORTO01Exec()

  Local oModel := FWLoadModel("FUNAKI_ORTO001")

  Local oHeader := oModel:getModel('HEADER')
  Local oItems := oModel:getModel('ITEMS')

  Local aButtons := {}

  if Aviso('ExecAuto','Deseja executar a rotina automatica?', {'Sim', 'Nao'}) == 2
    return
  endif

  oModel:setOperation(MODEL_OPERATION_INSERT)
  oModel:activate()

  oHeader:setValue('Z10_CODIGO', retNum(time()))
  oHeader:setValue('Z10_DESCRI', 'DESCRICAO DA HORA ' + time())
  oHeader:setValue('Z10_PRODUT', PadR('000006', 15))

  loadItems(oModel)

  oItems:goLine(oItems:addLine())

  oItems:setValue('Z11_PRODUT', PadR('000006', 15))
  oItems:setValue('Z11_QTDPAD', 15)
  oItems:setValue('Z11_SLDATU', 8)

  oItems:goLine(1)

  if Aviso('ExecAuto','Deseja ver ou salvar?', {'Ver', 'Salvar'}) == 1

    //habilita apenas botoes de Salvar e Cancelar
    aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,"Salvar o novo Kit"},{.T.,"Cancelar"},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}}

    FWExecView("Cadastro de Kits", "FUNAKI_ORTO001", MODEL_OPERATION_INSERT,,,,,aButtons,,,, oModel)

  else

    if oModel:vldData()
      oModel:commitData()
      Alert('Gravado sucesso')
    else
      alert(varInfo('erro',oModel:GetErrorMessage()))
    endif

  endif


return