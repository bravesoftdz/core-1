unit fre_dbbusiness;

{
(§LIC)
  (c) Autor,Copyright
      Dipl.Ing.- Helmut Hartl, Dipl.Ing.- Franz Schober, Dipl.Ing.- Christian Koch
      FirmOS Business Solutions GmbH
      www.openfirmos.org
      New Style BSD Licence (OSI)

  Copyright (c) 2001-2013, FirmOS Business Solutions GmbH
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

      * Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation
        and/or other materials provided with the distribution.
      * Neither the name of the <FirmOS Business Solutions GmbH> nor the names
        of its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
(§LIC_END)
} 

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}

interface

uses
  Classes, SysUtils,FOS_TOOL_INTERFACES,
  FRE_DB_COMMON,
  FRE_DB_INTERFACE;

procedure Register_DB_Extensions;

type

  { TFRE_DB_COUNTRY }

  TFRE_DB_COUNTRY = class(TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  end;

  { TFRE_DB_ADDRESS }

  TFRE_DB_ADDRESS = class(TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  end;

  { TFRE_DB_Site }

  TFRE_DB_Site = class (TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  published
    function IMI_Content            (const input:IFRE_DB_Object):IFRE_DB_Object;
    function IMI_Menu               (const input:IFRE_DB_Object):IFRE_DB_Object;
    function IMI_AddEndpoint        (const input:IFRE_DB_Object):IFRE_DB_Object;
    function IMI_AddMobileDevice    (const input:IFRE_DB_Object):IFRE_DB_Object;
    function IMI_ChildrenData       (const input:IFRE_DB_Object):IFRE_DB_Object;
  end;


  { TFRE_DB_Phone }

  TFRE_DB_Phone  = class (TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
  end;


  TFRE_DB_EADDRESS = class (TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
  end;

  TFRE_DB_MAILADDRESS = class(TFRE_DB_EADDRESS)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
  end;

  TFRE_DB_WEBADDRESS = class(TFRE_DB_EADDRESS)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
  end;

  { TFRE_DB_Contact }

  TFRE_DB_Contact  = class (TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  end;

  { TFRE_DB_Tenant }

  TFRE_DB_Tenant  = class (TFRE_DB_Contact)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
  published
    function IMI_addCustomer(const input:IFRE_DB_Object):IFRE_DB_Object;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  end;

  { TFRE_DB_Customer }

  TFRE_DB_Customer = class (TFRE_DB_Contact)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  published
   function IMI_Menu              (const input:IFRE_DB_Object):IFRE_DB_Object;
   function IMI_Edit              (const input:IFRE_DB_Object):IFRE_DB_Object;
   function IMI_addSite           (const input:IFRE_DB_Object):IFRE_DB_Object;
  end;

  { TFRE_DB_GEOPOSITION }

  TFRE_DB_GEOPOSITION = class(TFRE_DB_ObjectEx)
  protected
    class procedure RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT); override;
    class procedure InstallDBObjects    (const conn:IFRE_DB_SYS_CONNECTION); override;
  end;

implementation

class procedure TFRE_DB_WEBADDRESS.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
begin
  inherited RegisterSystemScheme(scheme);
  scheme.SetParentSchemeByName('TFRE_DB_EADDRESS');
end;

class procedure TFRE_DB_MAILADDRESS.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
begin
  inherited RegisterSystemScheme(scheme);
  scheme.SetParentSchemeByName('TFRE_DB_EADDRESS');
end;

class procedure TFRE_DB_EADDRESS.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
begin
  inherited RegisterSystemScheme(scheme);
  scheme.AddSchemeField('url',fdbft_String).required:=true;
end;

class procedure TFRE_DB_COUNTRY.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.GetSchemeField('objname').required:=true;
  scheme.AddSchemeField('tld',fdbft_String);
  scheme.SetSysDisplayField(GFRE_DBI.ConstructStringArray(['objname','tld']),'%s (%s)');
  group:=scheme.AddInputGroup('main').Setup('$scheme_TFRE_DB_COUNTRY_country_group');
  group.AddInput('objname','$scheme_TFRE_DB_COUNTRY_name');
  group.AddInput('tld','$scheme_TFRE_DB_COUNTRY_tld');
end;

class procedure TFRE_DB_COUNTRY.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  inherited InstallDBObjects(conn);
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_COUNTRY_country_group','Country'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_COUNTRY_name','Country Name'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_COUNTRY_tld','Country TLD'));
end;

class procedure TFRE_DB_ADDRESS.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.AddSchemeField('street',fdbft_String).required:=true;
  scheme.AddSchemeField('nr',fdbft_String).required:=true;
  scheme.AddSchemeField('stair',fdbft_String);
  scheme.AddSchemeField('floor',fdbft_String);
  scheme.AddSchemeField('door',fdbft_String);
  scheme.AddSchemeField('co',fdbft_String);
  scheme.AddSchemeField('city',fdbft_String).required:=true;
  scheme.AddSchemeField('zip',fdbft_String).required:=true;
  scheme.AddSchemeFieldSubscheme('country','TFRE_DB_COUNTRY').required:=true;

  group:=scheme.AddInputGroup('main').Setup('scheme');
  group.AddInput('street','$scheme_TFRE_DB_ADDRESS_street');
  group.AddInput('nr','$scheme_TFRE_DB_ADDRESS_nr');
  group.AddInput('stair','$scheme_TFRE_DB_ADDRESS_stair');
  group.AddInput('floor','$scheme_TFRE_DB_ADDRESS_floor');
  group.AddInput('door','$scheme_TFRE_DB_ADDRESS_door');
  group.AddInput('co','$scheme_TFRE_DB_ADDRESS_co');
  group.AddInput('city','$scheme_TFRE_DB_ADDRESS_city');
  group.AddInput('zip','$scheme_TFRE_DB_ADDRESS_zip');
  group.AddInput('country','$scheme_TFRE_DB_ADDRESS_country',false,false,'country');
end;

class procedure TFRE_DB_ADDRESS.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  inherited InstallDBObjects(conn);
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_street','Street'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_nr','Nr'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_stair','Stair'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_floor','Floor'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_door','Door'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_co','Care off'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_city','City'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_zip','ZIP'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_ADDRESS_country','Country'));
end;

class procedure TFRE_DB_GEOPOSITION.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.AddSchemeField('longitude',fdbft_Real64).required:=true;
  scheme.AddSchemeField('latitude',fdbft_Real64).required:=true;
  group:=scheme.AddInputGroup('main').Setup('$scheme_TFRE_DB_GEOPOSITION_main_group');
  group.AddInput('longitude','$scheme_TFRE_DB_GEOPOSITION_longitude');
  group.AddInput('latitude','$scheme_TFRE_DB_GEOPOSITION_latitude');
end;

class procedure TFRE_DB_GEOPOSITION.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  inherited InstallDBObjects(conn);
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_GEOPOSITION_main_group','Geoposition'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_GEOPOSITION_longitude','Longitude'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_GEOPOSITION_latitude','Latitude'));
end;

class procedure TFRE_DB_Phone.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
begin
  inherited RegisterSystemScheme(scheme);
  scheme.AddSchemeField('number',fdbft_String).required:=true;
end;

class procedure TFRE_DB_Contact.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.Explanation:='Base scheme for all contacts<br>(persons, customers, tenant)';
  scheme.AddSchemeField('firstname',fdbft_String).required:=true;
  scheme.AddSchemeField('lastname',fdbft_String).required:=true;
  scheme.AddSchemeField('company',fdbft_String);
  scheme.AddSchemeFieldSubscheme('mainaddress','TFRE_DB_ADDRESS').required:=true;
  scheme.AddSchemeFieldSubscheme('deliveryaddress','TFRE_DB_ADDRESS');
  scheme.AddSchemeFieldSubscheme('businessphone','TFRE_DB_PHONE');
  scheme.AddSchemeFieldSubscheme('mobilephone','TFRE_DB_PHONE');
  scheme.AddSchemeFieldSubscheme('privatephone','TFRE_DB_PHONE');
  scheme.AddSchemeFieldSubscheme('mail','TFRE_DB_MAILADDRESS');
  scheme.AddSchemeFieldSubscheme('http','TFRE_DB_WEBADDRESS');

  group:=scheme.AddInputGroup('main').Setup('$scheme_TFRE_DB_CONTACT_main_group');
  group.AddInput('company','$scheme_TFRE_DB_CONTACT_company');
  group.AddInput('firstname','$scheme_TFRE_DB_CONTACT_firstname');
  group.AddInput('lastname','$scheme_TFRE_DB_CONTACT_lastname');

  group:=scheme.AddInputGroup('address').Setup('$scheme_TFRE_DB_CONTACT_address_group');
  group.UseInputGroup('TFRE_DB_ADDRESS','main','mainaddress');

  group:=scheme.AddInputGroup('address_delivery').Setup('$scheme_TFRE_DB_CONTACT_delivery_group');
  group.UseInputGroup('TFRE_DB_ADDRESS','main','deliveryaddress');

  group:=scheme.AddInputGroup('number').Setup('$scheme_TFRE_DB_CONTACT_number_group');
  group.AddInput('businessphone.number','$scheme_TFRE_DB_CONTACT_bnumber');
  group.AddInput('mobilephone.number','$scheme_TFRE_DB_CONTACT_mnumber');
  group.AddInput('privatephone.number','$scheme_TFRE_DB_CONTACT_pnumber');

  group:=scheme.AddInputGroup('eaddresses').Setup('$scheme_TFRE_DB_CONTACT_eaddress_group');
  group.AddInput('mail.url','$scheme_TFRE_DB_CONTACT_mail');
  group.AddInput('http.url','$scheme_TFRE_DB_CONTACT_web');
end;

class procedure TFRE_DB_Contact.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  inherited InstallDBObjects(conn);
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_main_group','General Information'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_address_group','Mainaddress'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_delivery_group','Deliveryaddress'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_number_group','Phone Numbers'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_eaddress_group','EContact'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_company','Company'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_firstname','Firstname'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_lastname','Lastname'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_bnumber','Business'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_mnumber','Mobile'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_pnumber','Private'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_mail','EMail'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CONTACT_web','Web'));
end;

{ TFRE_DB_Customer }

class procedure TFRE_DB_Customer.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.SetParentSchemeByName('TFRE_DB_CONTACT');
  scheme.AddSchemeField('tenantid',fdbft_ObjLink).required:=true;
  scheme.AddSchemeField('customernumber',fdbft_String).required:=true;

  group:=scheme.AddInputGroup('main').Setup('$scheme_TFRE_DB_CUSTOMER_main_group');
  group.AddInput('customernumber','$scheme_TFRE_DB_CUSTOMER_number');
  group.AddInput('tenantid','',false,true);
  group.UseInputGroup('TFRE_DB_CONTACT','main');
end;

class procedure TFRE_DB_Customer.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CUSTOMER_main_group','Customer Information'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_CUSTOMER_number','Number'));
end;

function TFRE_DB_Customer.IMI_Menu(const input: IFRE_DB_Object): IFRE_DB_Object;
var  res: TFRE_DB_MENU_DESC;
begin
  res:=TFRE_DB_MENU_DESC.create.Describe();
  res.AddEntry.Describe('Add Site','images_apps/business/customer_add_site.png',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(Self,'addSite'));
  res.AddEntry.Describe('Edit','images_apps/business/modify_customer.png',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(Self,'edit'));
  res.AddEntry.Describe('Delete','images_apps/business/delete_customer.png',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(self,'deleteOperation'));
  Result:=res;
end;

function TFRE_DB_Customer.IMI_Edit(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res    : TFRE_DB_DIALOG_DESC;
  scheme : IFRE_DB_SchemeObject;
begin
  GetDBConnection.GetScheme(SchemeClass,scheme);

  res:=TFRE_DB_DIALOG_DESC.Create.Describe('Edit Customer');
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('address'),GetSession(input)).SetCollapseState(true);
  res.AddSchemeFormGroup(scheme.GetInputGroup('address_delivery'),GetSession(input)).SetCollapseState(true);
  res.AddSchemeFormGroup(scheme.GetInputGroup('number'),GetSession(input)).SetCollapseState(true);
  res.AddSchemeFormGroup(scheme.GetInputGroup('eaddresses'),GetSession(input)).SetCollapseState(true);
  res.FillWithObjectValues(Self,GetSession(input));
  res.AddButton.Describe('Save',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(Self,'saveOperation'),fdbbt_submit);
  Result:=res;
end;

function TFRE_DB_Customer.IMI_addSite(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res       : TFRE_DB_DIALOG_DESC;
  scheme    : IFRE_DB_SchemeObject;
  serverFunc: TFRE_DB_SERVER_FUNC_DESC;
begin
  GetDBConnection.GetScheme('TFRE_DB_SITE',scheme);

  res:=TFRE_DB_DIALOG_DESC.Create.Describe('Add Site');
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('address'),GetSession(input));

  res.SetElementValue('customerid',UID_String);
  serverFunc:=TFRE_DB_SERVER_FUNC_DESC.Create.Describe('TFRE_DB_SITE','newOperation');
  serverFunc.AddParam.Describe('collection','site');
  res.AddButton.Describe('Save',serverFunc,fdbbt_submit);
  Result:=res;
end;

{ TFRE_DB_Tenant }

class procedure TFRE_DB_Tenant.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
begin
  inherited RegisterSystemScheme(scheme);
  scheme.SetParentSchemeByName('TFRE_DB_CONTACT');
   //constraints
   // TFRE_DB_CUSTOMER:
   // tenantid must link to existend TFRE_DB_TENANT
   // customernumber must be unique per tenant
   // TFRE_DB_COUNTRY:
   // name and tld must be unique
   // TFRE_DB_ADDRESS:
   // country must link to existend TFRE_DB_COUNTRY
end;

function TFRE_DB_Tenant.IMI_addCustomer(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res       : TFRE_DB_DIALOG_DESC;
  scheme    : IFRE_DB_SchemeObject;
  serverFunc: TFRE_DB_SERVER_FUNC_DESC;
begin
  GetDBConnection.GetScheme('TFRE_DB_CUSTOMER',scheme);
  res:=TFRE_DB_DIALOG_DESC.Create.Describe('Add Customer');
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('address'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('address_delivery'),GetSession(input)).SetCollapseState(true);
  res.AddSchemeFormGroup(scheme.GetInputGroup('number'),GetSession(input)).SetCollapseState(true);
  res.AddSchemeFormGroup(scheme.GetInputGroup('eaddresses'),GetSession(input)).SetCollapseState(true);

  res.SetElementValue('tenantid',GFRE_BT.GUID_2_HexString(UID));
  serverFunc:=TFRE_DB_SERVER_FUNC_DESC.Create.Describe('TFRE_DB_CUSTOMER','newOperation');
  serverFunc.AddParam.Describe('collection','customer');
  res.AddButton.Describe('Save',serverFunc,fdbbt_submit);
  Result:=res;
end;

class procedure TFRE_DB_Tenant.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  // Do nothing
  //inherited InstallDBObjects(conn);
end;


{ TFRE_DB_Site }

class procedure TFRE_DB_Site.RegisterSystemScheme(const scheme: IFRE_DB_SCHEMEOBJECT);
var group : IFRE_DB_InputGroupSchemeDefinition;
begin
  inherited RegisterSystemScheme(scheme);
  scheme.GetSchemeField('objname').required:=true;
  scheme.AddSchemeField('sitekey',fdbft_String);
  scheme.AddSchemeField('customerid',fdbft_ObjLink).required:=true;
  scheme.AddSchemeFieldSubscheme('position','TFRE_DB_GEOPOSITION').required:=false;
  scheme.AddSchemeFieldSubscheme('address','TFRE_DB_ADDRESS').required:=false;
  scheme.AddSchemeField('extension',fdbft_ObjLink);

  group:=scheme.AddInputGroup('main').Setup('$scheme_TFRE_DB_SITE_main_group');
  group.AddInput('objname','$scheme_TFRE_DB_SITE_name');
  group.AddInput('sitekey','$scheme_TFRE_DB_SITE_key');
  group.AddInput('customerid','',false,true);
  group:=scheme.AddInputGroup('address').Setup('$scheme_TFRE_DB_SITE_address_group');
  group.UseInputGroup('TFRE_DB_ADDRESS','main','address');
  group.UseInputGroup('TFRE_DB_GEOPOSITION','main','position');
end;

class procedure TFRE_DB_Site.InstallDBObjects(const conn: IFRE_DB_SYS_CONNECTION);
begin
  inherited InstallDBObjects(conn);
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_SITE_main_group','General Information'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_SITE_address_group','Site Address'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_SITE_name','Name'));
  conn.StoreTranslateableText(GFRE_DBI.CreateText('$scheme_TFRE_DB_SITE_key','Key'));
end;

function TFRE_DB_Site.IMI_Content(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res    : TFRE_DB_FORM_PANEL_DESC;
  scheme : IFRE_DB_SchemeObject;
begin
  GetDBConnection.GetScheme(SchemeClass,scheme);
  res:=TFRE_DB_FORM_PANEL_DESC.create.Describe('Site');
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('address'),GetSession(input));
  res.FillWithObjectValues(Self,GetSession(input));
  res.AddButton.Describe('Save',TFRE_DB_SERVER_FUNC_DESC.create.Describe(Self,'saveOperation'),fdbbt_submit);
  Result:=res;
end;

function TFRE_DB_Site.IMI_Menu(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res            : TFRE_DB_MENU_DESC;
  submenu        : TFRE_DB_SUBMENU_DESC;
  entry,subentry : TFRE_DB_MENU_ENTRY_DESC;
  param          : TFRE_DB_PARAM_DESC;
  serverfunc     : TFRE_DB_SERVER_FUNC_DESC;
  linksys,lancom : TFRE_DB_GUIDArray;
  add_linksys    : boolean;
  add_lancom     : boolean;

  procedure _addEPMenu (const endpointclass:string; const menutext:string; const dhcp:boolean);
  var
   subentry       : TFRE_DB_MENU_ENTRY_DESC;
   param          : TFRE_DB_PARAM_DESC;
   serverfunc     : TFRE_DB_SERVER_FUNC_DESC;

  begin
    serverfunc:=TFRE_DB_SERVER_FUNC_DESC.Create;
    serverfunc.Describe(Self,'addEndpoint');
    serverfunc.AddParam.Describe('endpointclass',endpointclass);
    if dhcp then begin
      serverfunc.AddParam.Describe('dhcp','true');
    end else begin
      serverfunc.AddParam.Describe('dhcp','false');
    end;
    subentry:=submenu.AddEntry.Describe(menutext,'images_apps/business/add_endpoint.png',serverfunc);
  end;

begin
  res:=TFRE_DB_MENU_DESC.create.Describe();


  linksys   := ReferencedByList('TFRE_DB_AP_LINKSYS');
  lancom    := ReferencedByList('TFRE_DB_AP_LANCOM');
  writeln ('Linksys:',length(linksys),' Lancom:',length(lancom));

  add_linksys := (length(linksys)=0)  and (length(lancom)=0);
  add_lancom  := (length(linksys)=0);

  if add_linksys or add_lancom then begin
    submenu   :=res.AddMenu.Describe('Add Endpoint','');
    if add_linksys then begin
      _addEPMenu('TFRE_DB_AP_LINKSYS_E1000','Linksys E1000',true);
      _addEPMenu('TFRE_DB_AP_LINKSYS_E1200','Linksys E1200',true);
      _addEPMenu('TFRE_DB_AP_LINKSYS_E1200V2','Linksys E1200V2',true);
    end;
    if add_lancom then begin
      _addEPMenu('TFRE_DB_AP_LANCOM_IAP321','Lancom IAP321',false);
      _addEPMenu('TFRE_DB_AP_LANCOM_OAP321','Lancom OAP321',false);
    end;
  end;
  res.AddEntry.Describe('Add Mobiledevice','images_apps/business/add_mobile_device.png',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(Self,'addMobileDevice'));
  res.AddEntry.Describe('Delete','images_apps/business/delete_site.png',TFRE_DB_SERVER_FUNC_DESC.Create.Describe(self,'deleteOperation'));


 Result:=res;
end;

function TFRE_DB_Site.IMI_AddEndpoint(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res           : TFRE_DB_DIALOG_DESC;
  scheme        : IFRE_DB_SchemeObject;
  serverFunc    : TFRE_DB_SERVER_FUNC_DESC;
  endpointclass : TFRE_DB_String;
  dhcp          : string;

begin
  endpointclass := input.Field('endpointclass').AsString;
  dhcp          := input.Field('dhcp').AsString;

  GetDBConnection.GetScheme(endpointclass,scheme);
  res:=TFRE_DB_DIALOG_DESC.Create.Describe('Add Accesspoint');
  res.SendChangedFieldsOnly(false);
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.AddSchemeFormGroup(scheme.GetInputGroup('options'),GetSession(input));

  res.SetElementValue('site',GFRE_BT.GUID_2_HexString(UID));
  res.SetElementValue('channel','0');
  res.SetElementValue('dhcp',dhcp);
  serverFunc:=TFRE_DB_SERVER_FUNC_DESC.Create.Describe(endpointclass,'newOperation');
  serverFunc.AddParam.Describe('collection','endpoint');
  res.AddButton.Describe('Save',serverFunc,fdbbt_submit);
  Result:=res;
end;

function TFRE_DB_Site.IMI_AddMobileDevice(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res       : TFRE_DB_DIALOG_DESC;
  scheme    : IFRE_DB_SchemeObject;
  serverFunc: TFRE_DB_SERVER_FUNC_DESC;
begin
  GetDBConnection.GetScheme('TFRE_DB_MOBILEDEVICE',scheme);
  res:=TFRE_DB_DIALOG_DESC.Create.Describe('Add Mobile Device');
  res.AddSchemeFormGroup(scheme.GetInputGroup('main'),GetSession(input));
  res.SetElementValue('site',GFRE_BT.GUID_2_HexString(UID));
  serverFunc:=TFRE_DB_SERVER_FUNC_DESC.Create.Describe('TFRE_DB_MOBILEDEVICE','newOperation');
  serverFunc.AddParam.Describe('collection','mobiledevice');
  res.AddButton.Describe('Save',serverFunc,fdbbt_submit);
  Result:=res;
end;


function TFRE_DB_Site.IMI_ChildrenData(const input: IFRE_DB_Object): IFRE_DB_Object;
var
  res   : TFRE_DB_STORE_DATA_DESC;
  childs: TFRE_DB_GUIDArray;
  i     : Integer;
  dbo   : IFRE_DB_Object;
  txt   : String;
  entry : IFRE_DB_Object;

begin
  res := TFRE_DB_STORE_DATA_DESC.create;
  childs:=ReferencedByList('TFRE_DB_DEVICE');
  for i := 0 to Length(childs) - 1 do begin
    GetDBConnection.Fetch(childs[i],dbo);
    if dbo.IsA('TFRE_DB_DEVICE') then begin
      if dbo.IsA('TFRE_DB_ENDPOINT') then begin
        txt:=dbo.field('Displayname').AsString;
      end else begin
        txt:=dbo.field('Name').AsString;
      end;

      entry:=GFRE_DBI.NewObject;
      entry.Field('text').AsString:=txt;
      entry.Field('uid').AsGUID:=dbo.UID;
      entry.Field('uidpath').AsStringArr:=dbo.GetUIDPath;
      entry.Field('_funcclassname_').AsString:=dbo.SchemeClass;
      entry.Field('_childrenfunc_').AsString:='ChildrenData';
      entry.Field('_menufunc_').AsString:='Menu';
      entry.Field('_contentfunc_').AsString:='Content';
      if not dbo.IsA('TFRE_DB_MobileDevice') then begin
        entry.Field('children').AsString:='UNCHECKED';
      end;
      res.addEntry(entry);
    end;
  end;
  Result:=res;
end;




procedure Register_DB_Extensions;
begin
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_EADDRESS);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_MAILADDRESS);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_WEBADDRESS);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_GEOPOSITION);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_COUNTRY);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_ADDRESS);

  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_Site);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_Phone);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_Contact);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_Tenant);
  GFRE_DBI.RegisterObjectClassEx(TFRE_DB_Customer);
  GFRE_DBI.Initialize_Extension_Objects;
end;

end.

