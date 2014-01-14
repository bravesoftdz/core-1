unit fre_db_persistance_common;

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

//BIG TODO : Remove Fillbytes and verify ART TREE FUNCTION
// VOLATILE Objects are not in WAL (or Cluster) (node local)

interface

uses
  Classes, SysUtils,FRE_SYSTEM,FRE_DB_COMMON,FRE_DB_INTERFACE,FRE_DB_CORE,FOS_ARRAYGEN,FOS_GENERIC_SORT,FOS_TOOL_INTERFACES,FOS_AlignedArray,FOS_REDBLACKTREE_GEN,
  fos_art_tree,fos_sparelistgen;

type
  TFRE_DB_WAL_Step_Type = (fdb_WAL_INSERT,fdb_WAL_UPDATE,fdb_WAL_DELETE_SUB_OBJECT,fdb_WAL_NEW_COLLECTION,fdb_WAL_DELETE_COLLECTION,fdb_WAL_CREATE_IDX,fdb_WAL_DROP_IDX,fdb_WAL_DELETE_OBJECT);

const
  CFRE_DB_WAL_Step_Type : array [TFRE_DB_WAL_Step_Type] of Char = ('I','U','d','C','Z','+','-','D');

type
  { TFRE_DB_IndexValueStore }

  TFRE_DB_IndexValueStore=class
  private
    FOBJArray  : TFRE_DB_GUIDArray;
    procedure  InternalCheck;
  public
    function    Exists           (const guid   : TGUID) : boolean;
    function    Add              (const objuid : TGuid) : boolean;
    //function    IndexedObjects   : TFRE_DB_ObjectArray;
    procedure   StreamToThis     (const stream:TStream);
    procedure   LoadFromThis     (const stream:TStream ; const coll: IFRE_DB_PERSISTANCE_COLLECTION);
    //procedure   ForAll           (const func : IFRE_DB_Obj_Iterator ; const ascending : boolean);
    function    ObjectCount      : NativeInt;
    procedure   AppendObjectUIDS (var uids:TFRE_DB_GUIDArray ; const ascending: boolean);
    function    RemoveUID        (const guid : TGUID) : boolean;
    constructor create           ;
    destructor  Destroy          ;override;
  end;

  { TFRE_DB_MM_Index }

  TFRE_DB_MM_Index=class
  private
    type
      tvaltype = (val_NULL,val_ZERO,val_VAL,val_NEG);
  protected
    FIndex           : TFRE_ART_TREE;
    FIndexName       : TFRE_DB_NameType;
    FUniqueName      : TFRE_DB_NameType;
    FFieldname       : TFRE_DB_NameType;
    FUniqueFieldname : TFRE_DB_NameType;
    FFieldType       : TFRE_DB_FIELDTYPE;
    FFixedKeylen     : NativeInt;
    FUnique          : Boolean;
    FAllowNull       : Boolean;
    FUniqueNullVals  : Boolean;
    FCollection      : IFRE_DB_PERSISTANCE_COLLECTION;
    //transient data
    //transkey        : Array [0..CFREA_maxKeyLen] of Byte;
    //transkeylen     : NativeInt;
    //updtranskey     : Array [0..CFREA_maxKeyLen] of Byte;
    //updtranskeylen  : NativeInt;
    //transient data end
    nullkey         :  Array [0..16] of Byte; // Nullkey is short in every domain
    nullkeylen      : NativeInt;

    procedure      _InternalCheckAdd                 (const key: PByte ; const keylen : Nativeint ; const isNullVal,isUpdate : Boolean ; const obj_uid : TGUID);
    procedure      _InternalCheckDel                 (const key: PByte ; const keylen : Nativeint ; const isNullVal          : Boolean ; const obj_uid : TGUID);
    procedure      _InternalAddGuidToValstore        (const key: PByte ; const keylen: Nativeint; const isNullVal: boolean; const uid: TGUID);
    procedure      _InternalRemoveGuidFromValstore   (const key: PByte ; const keylen: Nativeint; const isNullVal: boolean; const uid: TGUID);


    function       GetStringRepresentationOfTransientKey (const isnullvalue:boolean ; const key: PByte ; const keylen: Nativeint ): String;
    //procedure      SetTranformedKeyDBS               (const value : TFRE_DB_String ; const update_key : boolean ; const is_null_value : Boolean); virtual ;

    function       FetchIndexedValsTransformedKey    (var obj : TFRE_DB_GUIDArray ; const key: PByte ; const keylen : Nativeint):boolean;
    procedure      TransformToBinaryComparable       (fld:TFRE_DB_FIELD ; const key: PByte ; var keylen : Nativeint); virtual; abstract;
    function       CompareTransformedKeys            (const key1,key2: PByte ; const keylen1,keylen2 : Nativeint) : boolean;
    procedure      StreamHeader                      (const stream: TStream);virtual;
    procedure      StreamToThis                      (const stream: TStream);virtual;
    procedure      StreamIndex                       (const stream: TStream);virtual;
    procedure      LoadIndex                         (const stream: TStream ; const coll : IFRE_DB_PERSISTANCE_COLLECTION);virtual;
    class function CreateFromStream                  (const stream: TStream ; const coll : IFRE_DB_PERSISTANCE_COLLECTION):TFRE_DB_MM_Index;
    procedure      InitializeNullKey                 ; virtual ; abstract;
    function       _IndexIsFullUniqe                 : Boolean;
    function       _GetIndexStringSpec               : String;
  public
    constructor Create                               (const idx_name,fieldname: TFRE_DB_NameType ; const fieldtype : TFRE_DB_FIELDTYPE ; const unique : boolean ; const collection : IFRE_DB_PERSISTANCE_COLLECTION;const allow_null : boolean;const unique_null:boolean);
    destructor  Destroy                              ; override;
    function    Indexname                            : TFRE_DB_NameType;
    function    Uniquename                           : PFRE_DB_NameType;
    procedure   FieldTypeIndexCompatCheck            (fld:TFRE_DB_FIELD); virtual; abstract;
    function    NullvalueExists                      (var vals : TFRE_DB_IndexValueStore):boolean;
    function    NullvalueExistsForObject             (const obj             : TFRE_DB_Object):boolean; virtual;
    procedure   IndexAddCheck                        (const obj             : TFRE_DB_Object; const check_only : boolean); virtual; // Object is added
    procedure   IndexUpdCheck                        (const new_obj,old_obj : TFRE_DB_Object; const check_only : boolean); virtual; // Object gets changed
    procedure   IndexDelCheck                        (const obj,new_obj     : TFRE_DB_Object; const check_only : boolean); virtual; // Object gets deleted
    function    SupportsDataType                     (const typ : TFRE_DB_FIELDTYPE):boolean; virtual ; abstract;
    function    IsUnique                             : Boolean;
    procedure   AppendAllIndexedUids                 (var guids : TFRE_DB_GUIDArray ; const ascending: boolean ; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
    function    IndexTypeTxt                         : String ; virtual; abstract;
    function    IndexedCount                         (const unique_values : boolean): NativeInt;
    function    IndexIsFullyUnique                   : Boolean;
  end;


  { TFRE_DB_UnsignedIndex }

  TFRE_DB_UnsignedIndex=class(TFRE_DB_MM_Index)
  private
  protected
    procedure   InitializeNullKey           ; override;
  public
    procedure   TransformToBinaryComparable (fld:TFRE_DB_FIELD ; const key: PByte ; var keylen : Nativeint ); override;
    procedure   SetBinaryComparableKey      (const keyvalue:qword ; const key_target : PByte ; var key_len : NativeInt ; const is_null : boolean);
    constructor CreateStreamed              (const stream : TStream ; const idx_name, fieldname: TFRE_DB_NameType ; const fieldtype : TFRE_DB_FIELDTYPE ; const unique : boolean ; const collection : IFRE_DB_PERSISTANCE_COLLECTION;const allow_null:boolean;const unique_null:boolean);
    procedure   FieldTypeIndexCompatCheck   (fld:TFRE_DB_FIELD ); override;
    function    SupportsDataType            (const typ: TFRE_DB_FIELDTYPE): boolean; override;
    function    IndexTypeTxt                : String; override;
    procedure   ForAllIndexedUnsignedRange  (const min, max: QWord; var guids :  TFRE_DB_GUIDArray ; const ascending: boolean ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=-1 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean = false);
  end;

  { TFRE_DB_SignedIndex }

  TFRE_DB_SignedIndex=class(TFRE_DB_MM_Index)
  private
  protected
    procedure   InitializeNullKey           ; override;
  public
    procedure   TransformToBinaryComparable (fld:TFRE_DB_FIELD ; const key: PByte ; var keylen : Nativeint ); override;
    procedure   SetBinaryComparableKey      (const keyvalue:int64 ; const key_target : PByte ; var key_len : NativeInt ; const is_null : boolean);
    constructor CreateStreamed              (const stream: TStream; const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean; const unique_null: boolean);
    procedure   FieldTypeIndexCompatCheck   (fld:TFRE_DB_FIELD ); override;
    function    SupportsDataType            (const typ: TFRE_DB_FIELDTYPE): boolean; override;
    function    IndexTypeTxt                : String; override;
    procedure   ForAllIndexedSignedRange    (const min, max: int64; var guids :  TFRE_DB_GUIDArray ; const ascending: boolean ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=-1 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean = false);
  end;

  { TFRE_DB_TextIndex }

  TFRE_DB_TextIndex=class(TFRE_DB_MM_Index) //TODO Unicode Key Conversion
  private
    FCaseInsensitive : Boolean;
  protected
    procedure   SetBinaryComparableKey      (const keyvalue : TFRE_DB_String ; const key_target : PByte ; var key_len : NativeInt ; const is_null : boolean);
    procedure   StreamHeader                (const stream: TStream);override;
    procedure   InitializeNullKey           ; override;
  public
    constructor Create                      (const idx_name,fieldname: TFRE_DB_NameType ; const fieldtype : TFRE_DB_FIELDTYPE ; const unique, case_insensitive : boolean ; const collection : IFRE_DB_PERSISTANCE_COLLECTION;const allow_null : boolean;const unique_null:boolean);
    constructor CreateStreamed              (const stream : TStream ; const idx_name, fieldname: TFRE_DB_NameType ; const fieldtype : TFRE_DB_FIELDTYPE ; const unique : boolean ; const collection : IFRE_DB_PERSISTANCE_COLLECTION;const allow_null : boolean;const unique_null:boolean);
    procedure   FieldTypeIndexCompatCheck   (fld:TFRE_DB_FIELD ); override;
    procedure   TransformToBinaryComparable (fld:TFRE_DB_FIELD ; const key: PByte ; var keylen : Nativeint); override;
    function    SupportsDataType            (const typ: TFRE_DB_FIELDTYPE): boolean; override;
    function    IndexTypeTxt                : String; override;
    function    ForAllIndexedTextRange      (const min, max: TFRE_DB_String; var guids :  TFRE_DB_GUIDArray ; const ascending: boolean ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=-1 ; skipfirst : NativeInt=0  ; const only_count_unique_vals : boolean = false):boolean;
    function    ForAllIndexPrefixString     (const prefix  : TFRE_DB_String; var guids :  TFRE_DB_GUIDArray ; const index_name : TFRE_DB_NameType ; const ascending: boolean = true ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0  ; const only_count_unique_vals : boolean = false):boolean;
  end;

  { TFRE_DB_Persistance_Collection }

  TFRE_DB_Persistance_Collection=class(TObject,IFRE_DB_PERSISTANCE_COLLECTION,IFRE_DB_PERSISTANCE_COLLECTION_4_PERISTANCE_LAYER)
  private
    FName         : TFRE_DB_NameType;
    FUpperName    : TFRE_DB_NameType;
    FLayer        : IFRE_DB_PERSISTANCE_LAYER;
    FVolatile     : Boolean;
    FGuidObjStore : TFRE_ART_TREE;
    FIndexStore   : array of TFRE_DB_MM_INDEX;
    dummy         : PtrUInt;

    function      IsVolatile         : boolean;

    function      IndexExists      (const idx_name : TFRE_DB_NameType):NativeInt;
    procedure     AddIndex         (const idx : TFRE_DB_MM_Index);

    procedure     IndexAddCheck    (const obj              : TFRE_DB_Object;const check_only : boolean);
    procedure     IndexUpdCheck    (const new_obj, old_obj : TFRE_DB_Object;const check_only : boolean);
    procedure     IndexDelCheck    (const del_obj          : TFRE_DB_Object;const check_only : boolean);

    procedure     StoreInThisColl     (const new_obj         : TFRE_DB_Object ; const checkphase : boolean);
    procedure     UpdateInThisColl    (const new_fld,old_fld : TFRE_DB_FIELD  ; const old_obj,new_obj : TFRE_DB_Object ; const update_typ : TFRE_DB_ObjCompareEventType ; const checkphase : boolean);


    procedure     DeleteFromThisColl  (const del_obj         : TFRE_DB_Object ; const checkphase : boolean);

    function      CloneOutObject   (const inobj:TFRE_DB_Object):TFRE_DB_Object;
    function      CloneOutArray    (const objarr : TFRE_DB_GUIDArray):TFRE_DB_ObjectArray;

    procedure     StreamToThis     (const stream : TStream);
    procedure     LoadFromThis     (const stream : TStream);

    function      _GetIndexedObjUids  (const query_value: TFRE_DB_String; out arr: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean): boolean;
    function      FetchIntFromColl    (const uid:TGuid ; var obj : TFRE_DB_Object):boolean;
  public
    function    CollectionName     (const unique:boolean):TFRE_DB_NameType;
    function    GetPersLayerIntf   : IFRE_DB_PERSISTANCE_COLLECTION_4_PERISTANCE_LAYER;
    function    UniqueName         : PFRE_DB_NameType;
    constructor Create             (const coll_name: TFRE_DB_NameType; Volatile: Boolean; const pers_layer: IFRE_DB_PERSISTANCE_LAYER);
    destructor  Destroy            ; override;
    function    Count              : int64;
    function    Exists             (const ouid: TGUID): boolean;


    procedure   Clear              ; // Clear Store but dont free

    procedure   GetAllUIDS         (var uids : TFRE_DB_GUIDArray);

    function    Store              (var   new_obj : TFRE_DB_Object):TFRE_DB_Errortype;
    function    Delete             (const ouid    : TGUID):TFRE_DB_Errortype;

    function    Fetch              (const uid:TGUID ; var obj : TFRE_DB_Object) : boolean;
    function    First              : TFRE_DB_Object;
    function    Last               : TFRE_DB_Object;
    function    GetItem            (const num:uint64) : TFRE_DB_Object;
    function    DefineIndexOnField (const FieldName   : TFRE_DB_NameType ; const FieldType : TFRE_DB_FIELDTYPE   ; const unique     : boolean ; const ignore_content_case: boolean ; const index_name : TFRE_DB_NameType ; const allow_null_value : boolean=true ; const unique_null_values: boolean=false): TFRE_DB_Errortype;

    function    GetIndexedObj      (const query_value : TFRE_DB_String   ; out   obj       : TFRE_DB_Object      ; const index_name : TFRE_DB_NameType='def'):boolean; // for the string fieldtype
    function    GetIndexedObj      (const query_value : TFRE_DB_String   ; out   obj       : TFRE_DB_ObjectArray ; const index_name : TFRE_DB_NameType='def' ; const check_is_unique : boolean=false):boolean; overload ;
    function    GetIndexedUID      (const query_value : TFRE_DB_String   ; out obj_uid     : TGUID               ; const index_name : TFRE_DB_NameType='def'): boolean;
    function    GetIndexedUID      (const query_value : TFRE_DB_String   ; out obj_uid     : TFRE_DB_GUIDArray   ; const index_name : TFRE_DB_NameType='def' ; const check_is_unique : boolean=false):boolean; overload ;

    procedure   ForAllIndexed              (var guids : TFRE_DB_GUIDArray ; const index_name:TFRE_DB_NameType='def'; const ascending:boolean=true ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean=false);

    procedure   ForAllIndexedSignedRange   (const min_value,max_value : int64          ; var   guids    : TFRE_DB_GUIDArray ; const index_name : TFRE_DB_NameType ; const ascending: boolean = true ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean=false);
    procedure   ForAllIndexedUnsignedRange (const min_value,max_value : QWord          ; var   guids    : TFRE_DB_GUIDArray ; const index_name : TFRE_DB_NameType ; const ascending: boolean = true ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean=false);
    procedure   ForAllIndexedStringRange   (const min_value,max_value : TFRE_DB_String ; var   guids    : TFRE_DB_GUIDArray ; const index_name : TFRE_DB_NameType ; const ascending: boolean = true ; const min_is_null : boolean = false ; const max_is_max : boolean = false ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean=false);
    procedure   ForAllIndexPrefixString    (const prefix              : TFRE_DB_String ; var   guids    : TFRE_DB_GUIDArray; const index_name : TFRE_DB_NameType ; const ascending: boolean = true ; const max_count : NativeInt=0 ; skipfirst : NativeInt=0 ; const only_count_unique_vals : boolean=false);


    procedure   CheckFieldChangeAgainstIndex (const oldfield,newfield : TFRE_DB_FIELD ; const change_type : TFRE_DB_ObjCompareEventType ; const check : boolean ; const old_obj,new_obj : TFRE_DB_Object);
  end;

  { TFRE_DB_CollectionTree }

  { TFRE_DB_CollectionManageTree }

  TFRE_DB_PersColl_Iterator = function(const coll:IFRE_DB_PERSISTANCE_COLLECTION):boolean is nested;


  TFRE_DB_CollectionManageTree = class
  private
    FCollTree : TFRE_ART_TREE;
    dummy     : PtrUInt;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Clear;
    function    NewCollection     (const coll_name : TFRE_DB_NameType ; out Collection:IFRE_DB_PERSISTANCE_COLLECTION ; const volatile_in_memory:boolean ; const pers_layer:IFRE_DB_PERSISTANCE_LAYER) : TFRE_DB_Errortype;
    function    DeleteCollection  (const coll_name : TFRE_DB_NameType):TFRE_DB_Errortype;
    function    GetCollection     (const coll_name : TFRE_DB_NameType ; out Collection:IFRE_DB_PERSISTANCE_COLLECTION) : boolean;
    procedure   ForAllCollections (const iter : TFRE_DB_PersColl_Iterator);
  end;

  //TFRE_DB_REF_TYPE=(fredb_REFOUTBOUND,fredb_REFINBOUND);

  //RFRE_DB_GUID_RefLink_Out_Key = packed record
  //  GUID      : Array [0..15] of Byte;
  //  RefTyp    : Byte;  // 17 Bytes // Outlink = $99 // Inlink= $AA
  //  FieldName : Array [0..62] of Byte;
  //end;
  //PFRE_DB_GUID_RefLink_Out_Key = ^RFRE_DB_GUID_RefLink_Out_Key;

  RFRE_DB_GUID_RefLink_InOut_Key = packed record
    GUID            : Array [0..15] of Byte;
    RefTyp          : Byte; // 17 Bytes // Outlink = $99 // Inlink= $AA
    ToFromGuid      : Array [0..15] of Byte;  // 25 Bytes // Outlink = $99 // Inlink= $AA
    SchemeSepField  : Array [0..129] of Byte; // VARIABLE LENGTH(!) // TODO THINK ABOUT filter prefix scan (schemeclass) "SCHEME|FIELD"
    KeyLength       : Byte; // Length (not part of key)
  end;
  PFRE_DB_GUID_RefLink_In_Key = ^RFRE_DB_GUID_RefLink_InOut_Key;


  //{ TREF_LinkEncapsulation }

  //TREF_LinkEncapsulation=class(Tobject)
  //private
  //  FLinks : TFRE_DB_GUIDArray;
  //public
  //  constructor Create (const links : TFRE_DB_GUIDArray);
  //  function    Links  : TFRE_DB_GUIDArray;
  //end;

  { TFRE_DB_Master_Data }

  TFRE_DB_Master_Data=class(TObject)
  private
    F_DB_TX_Number             : Qword;
    FMastername                : String;
    FMasterPersistantObjStore  : TFRE_ART_TREE;
    FMasterVolatileObjStore    : TFRE_ART_TREE;
    FMasterRefLinks            : TFRE_ART_TREE;
    FMasterCollectionStore     : TFRE_DB_CollectionManageTree;
    FLayer                     : IFRE_DB_PERSISTANCE_LAYER;

    function     GetOutBoundRefLinks        (const from_obj : TGUID): TFRE_DB_ObjectReferences;
    function     GetInboundLinks            (const to_obj   : TGUID): TFRE_DB_ObjectReferences;

    procedure    __SetupOutboundLinkKey     (const from_uid,to_uid: TFRE_DB_GUID ; const scheme_link_key : TFRE_DB_NameTypeRL ; var refoutkey : RFRE_DB_GUID_RefLink_InOut_Key); //inline;
    procedure    __SetupInboundLinkKey      (const from_uid,to_uid: TFRE_DB_GUID ; const scheme_link_key : TFRE_DB_NameTypeRL ; var refinkey  : RFRE_DB_GUID_RefLink_InOut_Key); //inline;
    procedure    __SetupInitialRefLink      (const from_key : TFRE_DB_Object ; const FromFieldToSchemename,LinkFromSchemenameField: TFRE_DB_NameTypeRL ; const references_to : TFRE_DB_GUID);
    procedure    _SetupInitialRefLinks      (const from_key : TFRE_DB_Object ; const references_to_list : TFRE_DB_ObjectReferences ; const schemelink_arr : TFRE_DB_NameTypeRLArray);
    function     __RefLinkOutboundExists    (const from_uid: TFRE_DB_GUID;const  fieldname: TFRE_DB_NameType; to_object: TFRE_DB_GUID; const scheme_link: TFRE_DB_NameTypeRL):boolean;
    function     __RefLinkInboundExists     (const from_uid: TFRE_DB_GUID;const  fieldname: TFRE_DB_NameType; to_object: TFRE_DB_GUID; const scheme_link: TFRE_DB_NameTypeRL):boolean;
    procedure    __CheckReferenceLink       (const obj: TFRE_DB_Object; fieldname: TFRE_DB_NameType; link: TFRE_DB_GUID ; var scheme_link : TFRE_DB_NameTypeRL);
    procedure    _ChangeRefLink             (const from_obj : TFRE_DB_Object ; const fieldname: TFRE_DB_NameType ; const references_to_list : TFRE_DB_GUIDArray);

    // Check full referential integrity, check if to objects exist
    procedure    _CheckRefIntegrityForObject (const obj:TFRE_DB_Object ; var ref_array : TFRE_DB_ObjectReferences ; var schemelink_arr : TFRE_DB_NameTypeRLArray);

    // Remove a reflinkfield, delete refence to and from indexes
    function     _RemoveRefLinkFieldDelRefs (const obj:TFRE_DB_Object ; field : TFRE_DB_FIELD ; const check_only : boolean):TFRE_DB_Errortype;

  public
    function     FetchNewTransactionID (const transid:string):String;

    function     InternalStoreObjectFromStable (const obj : TFRE_DB_Object) : TFRE_DB_Errortype;
    function     InternalRebuildRefindex                                    : TFRE_DB_Errortype;
    procedure    InternalStoreLock                                          ;

    procedure    DEBUG_CleanUpMasterData                                    ;

    constructor Create                (const master_name : string ; const Layer : IFRE_DB_PERSISTANCE_LAYER);
    destructor  Destroy               ; override;

    function    GetReferences         (const obj_uid:TGuid;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType=''):TFRE_DB_GUIDArray;
    function    GetReferencesCount    (const obj_uid:TGuid;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType=''):NativeInt;
    function    GetReferencesDetailed (const obj_uid:TGuid;const from:boolean ; const scheme_prefix_filter : TFRE_DB_NameType ='' ; const field_exact_filter : TFRE_DB_NameType=''):TFRE_DB_ObjectReferences;

    function    ExistsObject          (const obj_uid : TGuid ) : Boolean;
    function    FetchObject           (const obj_uid : TGuid ; var obj : TFRE_DB_Object ; const internal_obj : boolean) : boolean;
    procedure   StoreObject           (const obj     : TFRE_DB_Object  ; const check_only : boolean);
    procedure   DeleteObject          (const obj_uid : TGuid ; const check_only : boolean );
    procedure   ForAllObjectsInternal (const pers,volatile:boolean ; const iter:TFRE_DB_Obj_Iterator); // No Clone
    function    MasterColls           : TFRE_DB_CollectionManageTree;
    procedure   ApplyWAL              (const WALStream : TStream);
  end;

  TFRE_DB_TransactionalUpdateList = class;

  //FChangeList.ForAllBreak(@CheckForExistence);
  //FChangeList.ForAllBreak(@StoreInCollectionCheck);
  //FChangeList.ForAllBreak(@MasterStoreCheck);
  //FChangeList.ForAllBreak(@NeedsWalCheck);

  { TFRE_DB_ChangeStep }

  TFRE_DB_ChangeStep=class
  protected
    FIsStore       : Boolean; // TRUE = Store / False = UPDATE
    FIsWalReadBack : Boolean;
    FTransList     : TFRE_DB_TransactionalUpdateList;
    FStepID        : NativeInt;
    procedure  InternalWriteObject         (const m : TMemoryStream;const obj : TFRE_DB_Object);
    procedure  InternalReadObject          (const m : TStream ; var obj : TFRE_DB_Object);
  public
    function   Needs_WAL                   : Boolean; virtual; abstract;
    function   IsInsert                    : Boolean;
    procedure  CheckExistence              (const master : TFRE_DB_Master_Data); virtual;    // CHECK:  Is Existence required or bad ?
    procedure  WriteToWAL                  (const m:TMemoryStream); virtual ; abstract;
    procedure  WalReconstructionphase      (const master : TFRE_DB_Master_Data); virtual;   // Regenerate Step Data not written to WAL
    procedure  ChangeInCollectionCheckOrDo (const master : TFRE_DB_Master_Data ; const check : boolean); virtual ; abstract; { Do all collection related checks or stores (+collection indices) }
    procedure  MasterStore                 (const master : TFRE_DB_Master_Data ; const check : boolean); virtual ; abstract; { Do all objectc related checks or stores, (+reflink index) }
    class function CreateFromWal           (const wal : TStream) : TFRE_DB_Changestep;
    procedure  SetStepID                   (const id:NativeInt);
    function   GetTransActionStepID        : TFRE_DB_TransStepId;
  end;

  { TFRE_DB_NewCollectionStep }

  TFRE_DB_NewCollectionStep=class(TFRE_DB_ChangeStep)
  private
    FCollname       : TFRE_DB_NameType;
    FVolatile       : Boolean;
    FNewCollection  : IFRE_DB_PERSISTANCE_COLLECTION;
  public
    constructor Create                       (const coll_name: TFRE_DB_NameType;const volatile_in_memory: boolean);
    constructor CreateAsWALReadBack          (const coll_name: TFRE_DB_NameType);
    procedure   CheckExistence               (const master : TFRE_DB_Master_Data); override;
    procedure   ChangeInCollectionCheckOrDo  (const master: TFRE_DB_Master_Data; const check: boolean); override;
    procedure   MasterStore                  (const master: TFRE_DB_Master_Data; const check: boolean); override;
    function    Needs_WAL                    : Boolean; override;
    procedure   WriteToWAL                   (const m: TMemoryStream); override;
    function    GetNewCollection             : IFRE_DB_PERSISTANCE_COLLECTION;
  end;

  { TFRE_DB_DeleteCollectionStep }

  TFRE_DB_DeleteCollectionStep=class(TFRE_DB_ChangeStep)
  private
    FCollname       : TFRE_DB_NameType;
  public
    constructor Create                       (const coll_name: TFRE_DB_NameType);
    constructor CreateAsWALReadBack          (const coll_name: TFRE_DB_NameType);
    procedure   CheckExistence               (const master : TFRE_DB_Master_Data); override;
    procedure   ChangeInCollectionCheckOrDo  (const master: TFRE_DB_Master_Data; const check: boolean); override;
    procedure   MasterStore                  (const master: TFRE_DB_Master_Data; const check: boolean); override;
    function    Needs_WAL                    : Boolean; override;
    procedure   WriteToWAL                   (const m: TMemoryStream); override;
    function    GetNewCollection             : IFRE_DB_PERSISTANCE_COLLECTION;
  end;


  { TFRE_DB_InsertStep }

  TFRE_DB_InsertStep=class(TFRE_DB_ChangeStep)
  private
    FNewObj   : TFRE_DB_Object;
    FColl     : IFRE_DB_PERSISTANCE_COLLECTION;
    FCollName : TFRE_DB_NameType;
  public
    constructor Create                       (new_obj : TFRE_DB_Object ; const coll:IFRE_DB_PERSISTANCE_COLLECTION ; const is_store : boolean);  { ? is_store is used to differentiate the store from the update case}
    constructor CreateAsWalReadBack          (new_obj : TGuid ; const coll:TFRE_DB_NameType ; const is_store : boolean ; const ws:TStream);
    function    IsARootInsert                : Boolean;
    function    Needs_WAL: Boolean           ; override;
    function    CheckExistence               (const master : TFRE_DB_Master_Data ; const raise_ex:boolean): TFRE_DB_Errortype;
    procedure   ChangeInCollectionCheckOrDo  (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   MasterStore                  (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   WriteToWAL                   (const m:TMemoryStream);override;
  end;

  { TFRE_DB_InsertSubStep }

  TFRE_DB_InsertSubStep=class(TFRE_DB_ChangeStep)
  private
    FNewObj   : TFRE_DB_Object;
    FColl     : IFRE_DB_PERSISTANCE_COLLECTION;
    FCollName : TFRE_DB_NameType;
  public
    constructor Create                       (new_obj : TFRE_DB_Object ; const coll:IFRE_DB_PERSISTANCE_COLLECTION ; const is_store : boolean); { ? is_store is used to differentiate the store from the update case}
    constructor CreateAsWalReadBack          (new_obj : TGuid ; const coll:TFRE_DB_NameType ; const is_store : boolean ; const ws:TStream);
    function    IsARootInsert                : Boolean;
    function    Needs_WAL: Boolean           ; override;
    function    CheckExistence               (const master : TFRE_DB_Master_Data ; const raise_ex:boolean): TFRE_DB_Errortype;
    procedure   ChangeInCollectionCheckOrDo  (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   MasterStore                  (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   WriteToWAL                   (const m:TMemoryStream);override;
  end;


  { TFRE_DB_DeleteSubObjectStep }

  TFRE_DB_DeleteSubObjectStep=class(TFRE_DB_ChangeStep)
  private
    FDelObj  : TFRE_DB_Object;
    CollName : TFRE_DB_NameType;
    FObjPtr  : ^TFRE_DB_Object;
  public
    constructor Create                        (var del_obj : TFRE_DB_Object ; const from_coll : TFRE_DB_NameType ; const is_store : boolean); // all collections or a single collection
    function    Needs_WAL: Boolean            ; override;
    procedure   WriteToWAL                    (const m:TMemoryStream) ; override;
    procedure   ChangeInCollectionCheckOrDo   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   MasterStore                   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
  end;

  { TFRE_DB_DeleteObjectStep }

  TFRE_DB_DeleteObjectStep=class(TFRE_DB_ChangeStep)
  private
    FDelObj                : TFRE_DB_Object;
    CollName               : TFRE_DB_NameType;
    FObjPtr                : ^TFRE_DB_Object;
    FWouldNeedMasterDelete : Boolean;
  public
    constructor Create                        (var del_obj : TFRE_DB_Object ; const from_coll : TFRE_DB_NameType ; const is_store : boolean); // all collections or a single collection
    function    Needs_WAL: Boolean            ; override;
    procedure   WriteToWAL                    (const m:TMemoryStream) ; override;
    procedure   ChangeInCollectionCheckOrDo   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   MasterStore                   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
  end;


  TFRE_DB_UpdateStep=class;
  { TFRE_DB_UpdateStep }

  RFRE_DB_UpdateSubStep=record
    updtyp   : TFRE_DB_ObjCompareEventType;
    newfield : TFRE_DB_FIELD;
    oldfield : TFRE_DB_FIELD;
  end;

  TFRE_DB_UpdateStep=class(TFRE_DB_ChangeStep)
  private
    FSublist    : Array of RFRE_DB_UpdateSubStep;
    FCnt        : NativeInt;
    upobj       : TFRE_DB_Object;             // "new" object
    to_upd_obj  : TFRE_DB_Object;             // "old" object (Fields of object will be updated by newobjects fields)
    procedure   AddSubStep                    (const uptyp : TFRE_DB_ObjCompareEventType ; const new,old : TFRE_DB_FIELD);
  public
    constructor Create                        (obj,to_update_obj : TFRE_DB_Object ; const is_insert : boolean);
    constructor CreateAsWalReadBack           (new_obj : TGuid ; const is_store : boolean ; const ws:TStream);
    function    HasNoChanges                  : Boolean;
    function    Needs_WAL: Boolean            ; override;
    procedure   WriteToWAL                    (const m:TMemoryStream);override;
    procedure   ChangeInCollectionCheckOrDo   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
    procedure   MasterStore                   (const master : TFRE_DB_Master_Data ; const check : boolean); override;
  end;

  OFRE_SL_TFRE_DB_ChangeStep  = specialize OFOS_SpareList<TFRE_DB_ChangeStep>;

  { TFRE_DB_TransactionalUpdateList }

  PFRE_DB_ChangeStep = ^TFRE_DB_ChangeStep;

  TFRE_DB_TransactionalUpdateList = class(TObject)
  private
    FChangeList  : OFRE_SL_TFRE_DB_ChangeStep; // The sparse List has to be ordered (!) / deletetions and reinsertions must not happen
    FNotifyIf    : IFRE_DB_DBChangedNotification;
    FTransId     : TFRE_DB_NameType;
    FMaster      : TFRE_DB_Master_Data;
    FWalMem      : TMemoryStream;
    FNeedsWAL    : Boolean;
    procedure    ProcessCheck            (const WAL_RepairMode: boolean);
    function     Write_WAL_Or_DCC        (const Layer : IFRE_DB_PERSISTANCE_LAYER):boolean;
  public
    constructor  Create                  (const TransID : TFRE_DB_NameType ; const master_data : TFRE_DB_Master_Data);
    procedure    ReadFromBackWalStream   (const walstream : TStream);
    function     AddChangeStep           (const step:TFRE_DB_ChangeStep):NativeInt;

    procedure    GenerateAnObjChangeList (const store : boolean ; const obj : TFRE_DB_Object ; const collection_name : TFRE_DB_NameType);

    function     GetTransActionId        : TFRE_DB_NameType;
    function     GetTransLastStepTransId : TFRE_DB_TransStepId;
    function     GetNotifyIF             : IFRE_DB_DBChangedNotification;

    function     Commit                  (const Layer : IFRE_DB_PERSISTANCE_LAYER ; const WAL_RepairMode : boolean=false):boolean;
    procedure    Rollback                ;
    destructor   Destroy                 ;override;
  end;

  TFRE_DB_DBChangedNotificationBase = class(TObject,IFRE_DB_DBChangedNotification)
  protected
  public
    procedure  CollectionCreated (const coll_name : TFRE_DB_NameType ; const volatile : Boolean) ; virtual ; abstract;
    procedure  CollectionDeleted (const coll_name: TFRE_DB_NameType) ; virtual ; abstract;
  end;

implementation

{ TFRE_DB_InsertSubStep }

constructor TFRE_DB_InsertSubStep.Create(new_obj: TFRE_DB_Object; const coll: IFRE_DB_PERSISTANCE_COLLECTION; const is_store: boolean);
var cn:string;
begin
  FNewObj   := new_obj;
  FColl     := coll;
  FIsStore  := is_store;
  assert(not assigned(FNewObj.Parent));
end;

constructor TFRE_DB_InsertSubStep.CreateAsWalReadBack(new_obj: TGuid; const coll: TFRE_DB_NameType; const is_store: boolean; const ws: TStream);
begin
  FIsStore       := is_store;
  FCollName      := coll;
  FIsWalReadBack := true;
  InternalReadObject(ws,FNewObj);
  if not FREDB_Guids_Same(FNewObj.UID,new_obj) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'read back wal insertsubstep failed, uids mismatch [%s<>[%s]',[GFRE_BT.GUID_2_HexString(FNewObj.UID),GFRE_BT.GUID_2_HexString(new_obj)]);
end;


function TFRE_DB_InsertSubStep.IsARootInsert: Boolean;
begin

end;

function TFRE_DB_InsertSubStep.Needs_WAL: Boolean;
begin

end;

function TFRE_DB_InsertSubStep.CheckExistence(const master: TFRE_DB_Master_Data; const raise_ex: boolean): TFRE_DB_Errortype;
begin

end;

procedure TFRE_DB_InsertSubStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
begin

end;

procedure TFRE_DB_InsertSubStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
begin

end;

procedure TFRE_DB_InsertSubStep.WriteToWAL(const m: TMemoryStream);
begin

end;

{ TFRE_DB_DeleteCollectionStep }

constructor TFRE_DB_DeleteCollectionStep.Create(const coll_name: TFRE_DB_NameType);
begin
  FCollname      := coll_name;
end;

constructor TFRE_DB_DeleteCollectionStep.CreateAsWALReadBack(const coll_name: TFRE_DB_NameType);
begin
  FCollname      := coll_name;
end;

procedure TFRE_DB_DeleteCollectionStep.CheckExistence(const master: TFRE_DB_Master_Data);
var coll : IFRE_DB_PERSISTANCE_COLLECTION;
begin
  if not Master.MasterColls.GetCollection(FCollname,coll) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'collection [%s] does not exists!',[FCollname]);
end;

procedure TFRE_DB_DeleteCollectionStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
begin

end;

procedure TFRE_DB_DeleteCollectionStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
var res:TFRE_DB_Errortype;
begin
  if not check then
    begin
      res := Master.MasterColls.DeleteCollection(FCollname);
      if res<>edb_OK  then
        raise EFRE_DB_PL_Exception.Create(res,'failed to delete new collection [%s] in transaction step',[FCollname]);
      FTransList.GetNotifyIF.CollectionDeleted(FCollname);
    end;
end;

function TFRE_DB_DeleteCollectionStep.Needs_WAL: Boolean;
begin

end;

procedure TFRE_DB_DeleteCollectionStep.WriteToWAL(const m: TMemoryStream);
begin

end;

function TFRE_DB_DeleteCollectionStep.GetNewCollection: IFRE_DB_PERSISTANCE_COLLECTION;
begin

end;

{ TFRE_DB_DeleteObjectStep }

constructor TFRE_DB_DeleteObjectStep.Create(var del_obj: TFRE_DB_Object; const from_coll: TFRE_DB_NameType; const is_store: boolean);
begin
  FDelObj   := del_obj;
  FIsStore  := is_store;
  FObjPtr   := @del_obj;
  CollName  := from_coll;
  if CollName='' then
    FWouldNeedMasterDelete := true
  else
    FWouldNeedMasterDelete := false;
end;


function TFRE_DB_DeleteObjectStep.Needs_WAL: Boolean;
begin
  if FDelObj.IsVolatile then
    exit(false);
  if not FDelObj.IsObjectRoot then
    exit(false);
  result := true;
end;

procedure TFRE_DB_DeleteObjectStep.WriteToWAL(const m: TMemoryStream);
begin
  m.WriteAnsiString(CFRE_DB_WAL_Step_Type[fdb_WAL_DELETE_OBJECT]+BoolToStr(FIsStore,'1','0')+FDelObj.UID_String+CollName);
end;

procedure TFRE_DB_DeleteObjectStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
var arr : IFRE_DB_PERSISTANCE_COLLECTION_ARRAY;
      i : NativeInt;
     idx: NativeInt;
begin
  assert(IsInsert=false);
  if check
     and (CollName<>'') then
       begin
         if FDelObj.__InternalCollectionExistsName(CollName)=-1 then
           raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'the request to delete object [%s] from collection [%s] could not be completed, the object is not stored in the requested collection',[FDelObj.UID_String,CollName]);
       end;
  arr := FDelObj.__InternalGetCollectionList;
  if CollName='' then
    begin // Delete from all
      for i := 0 to high(arr) do
        begin
          arr[i].GetPersLayerIntf.DeleteFromThisColl(FDelObj,check);
        end;
    end
  else
    begin
      idx := FDelObj.__InternalCollectionExistsName(CollName); // Delete from this collection
      assert(idx<>-1);
      FDelObj.__InternalGetCollectionList[idx].GetPersLayerIntf.DeleteFromThisColl(FDelObj,check);
      if check
         and (Length(FDelObj.__InternalGetCollectionList)=1) then
           FWouldNeedMasterDelete:=true;
    end;
end;

procedure TFRE_DB_DeleteObjectStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
begin
  writeln('*****DELETE STEP .... REMOVING : ',FDelObj.UID_String);
  assert(IsInsert=false);
  if check
     and FWouldNeedMasterDelete then
       begin
         master.DeleteObject(FDelObj.UID,check);
       end;
  if not check then
    begin
      if length(FDelObj.__InternalGetCollectionList)=0 then
        begin
          master.DeleteObject(FDelObj.UID,check);
        end;
      FObjPtr^:=nil;
    end;
end;

{ TFRE_DB_NewCollectionStep }


constructor TFRE_DB_NewCollectionStep.Create(const coll_name: TFRE_DB_NameType; const volatile_in_memory: boolean);
begin
  FCollname      := coll_name;
  FVolatile      := volatile_in_memory;
end;

constructor TFRE_DB_NewCollectionStep.CreateAsWALReadBack(const coll_name: TFRE_DB_NameType);
begin
  FCollname      := coll_name;
  FVolatile      := false;
end;

procedure TFRE_DB_NewCollectionStep.CheckExistence(const master: TFRE_DB_Master_Data);
var coll : IFRE_DB_PERSISTANCE_COLLECTION;
begin
  if Master.MasterColls.GetCollection(FCollname,coll) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'collection [%s] already exists!',[FCollname]);
end;

procedure TFRE_DB_NewCollectionStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
begin

end;

procedure TFRE_DB_NewCollectionStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
var res:TFRE_DB_Errortype;
begin
  if not check then
    begin
      res := Master.MasterColls.NewCollection(FCollname,FNewCollection,FVolatile,Master.FLayer);
      if res<>edb_OK  then
        raise EFRE_DB_PL_Exception.Create(res,'failed to create new collectiion in step [%s] ',[FCollname]);
      FTransList.GetNotifyIF.CollectionCreated(FCollname,FVolatile);
    end;
end;

function TFRE_DB_NewCollectionStep.Needs_WAL: Boolean;
begin
  result := not (FVolatile);
end;

procedure TFRE_DB_NewCollectionStep.WriteToWAL(const m: TMemoryStream);
begin
  m.WriteAnsiString(CFRE_DB_WAL_Step_Type[fdb_WAL_NEW_COLLECTION]+FCollname);
end;

function TFRE_DB_NewCollectionStep.GetNewCollection: IFRE_DB_PERSISTANCE_COLLECTION;
begin
  result := FNewCollection;
end;

{ TFRE_DB_SignedIndex }

procedure TFRE_DB_SignedIndex.InitializeNullKey;
begin
  SetBinaryComparableKey(0,@nullkey,nullkeylen,true);
end;

procedure TFRE_DB_SignedIndex.TransformToBinaryComparable(fld: TFRE_DB_FIELD; const key: PByte; var keylen: Nativeint);
var val           : Int64;
    is_null_value : Boolean;
begin
  is_null_value := not assigned(fld);
  if not is_null_value then
    val := fld.AsInt64
  else
    val := 0;
  SetBinaryComparableKey(val,key,keylen,is_null_value)
end;

procedure TFRE_DB_SignedIndex.SetBinaryComparableKey(const keyvalue: int64; const key_target: PByte; var key_len: NativeInt; const is_null: boolean);
begin
  if not is_null then
    begin
      key_len := FFixedKeylen+1;
      case FFixedKeylen of
         2: PSmallInt(@key_target[1])^ := SwapEndian(SmallInt(keyvalue));
         4: PInteger(@key_target[1])^  := SwapEndian(Integer(keyvalue));
         8: PInt64(@key_target[1])^    := SwapEndian(keyvalue);
        else
          raise EFRE_DB_PL_Exception.Create(edb_UNSUPPORTED,'unsupported fixed length in index transform to binary comparable');
      end;
      key_target[1] := key_target[1] xor 128;
      key_target[0]:=1; // 0 , val , -val are ordered after NULL values which are prefixed by '0' not by '1'
    end
  else
    begin
      key_len := FFixedKeylen;
      FillByte(key_target[0],key_len,0);
    end;
end;

constructor TFRE_DB_SignedIndex.CreateStreamed(const stream: TStream; const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean;const unique_null:boolean);
begin
  Create(idx_name,fieldname,fieldtype,unique,collection,allow_null,unique_null);
  LoadIndex(stream,collection);
end;

procedure TFRE_DB_SignedIndex.FieldTypeIndexCompatCheck(fld: TFRE_DB_FIELD);
begin
  if not SupportsDataType(fld.FieldType) then
    raise EFRE_DB_PL_Exception.Create(edb_ILLEGALCONVERSION,'the signed index can only be used to index a signed number field, not a [%s] field.',[fld.FieldTypeAsString])
end;

function TFRE_DB_SignedIndex.SupportsDataType(const typ: TFRE_DB_FIELDTYPE): boolean;
begin
  case typ of
    fdbft_Int16,
    fdbft_Int32,
    fdbft_Int64,
    fdbft_DateTimeUTC,
    fdbft_Currency: result := true;
    else result := false;
  end;
end;

function TFRE_DB_SignedIndex.IndexTypeTxt: String;
begin
  result := 'signed'
end;

procedure TFRE_DB_SignedIndex.ForAllIndexedSignedRange(const min, max: int64; var guids: TFRE_DB_GUIDArray; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var lokey,hikey       : Array [0..8] of Byte;
    lokeylen,hikeylen : NativeInt;
    lokeyp,hikeyp     : PByte;

   procedure IteratorBreak(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var break : boolean);
   begin
     (FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore).AppendObjectUIDS(guids,ascending); // ForAllBreak(func,ascending,break);
   end;

begin
  if only_count_unique_vals=false then
    E_FOS_Implement;
  if not min_is_null then
    begin
      SetBinaryComparableKey(min,@lokey,lokeylen,min_is_null);
      lokeyp := lokey;
    end
  else
    lokeyp := nil;
  if not max_is_max then
    begin
      SetBinaryComparableKey(max,@hikey,hikeylen,max_is_max);
      hikeyp := hikey;
    end
  else
    hikeyp := nil;
  FIndex.RangeScan(lokeyp,hikeyp,lokeylen,hikeylen,@IteratorBreak,max_count,skipfirst,ascending)
end;

{ TFRE_DB_UnsignedIndex }

procedure TFRE_DB_UnsignedIndex.InitializeNullKey;
begin
  SetBinaryComparableKey(0,@nullkey,nullkeylen,true);
end;

procedure TFRE_DB_UnsignedIndex.TransformToBinaryComparable(fld: TFRE_DB_FIELD; const key: PByte; var keylen: Nativeint);
var val           : Qword;
    guid          : TGuid;
    is_null_value : boolean;

begin
  is_null_value := not assigned(fld);

  if (not is_null_value)
     and (fld.FieldType=fdbft_GUID) then
       guid   := fld.AsGUID;
  if (not is_null_value)
     and (fld.FieldType=fdbft_ObjLink) then
       guid   := fld.AsObjectLink;

  if FFixedKeylen=16 then
    begin
      if not is_null_value then
        begin
          move(guid,key^,sizeof(tguid));
          keylen:=16;
        end
      else
        begin
          FillByte(key^,17,0);
          keylen:=17;
        end
    end
  else
    begin
      if not is_null_value then
        val := fld.AsUInt64
      else
        val := 0;
      SetBinaryComparableKey(val,key,keylen,is_null_value)
    end;
end;

procedure TFRE_DB_UnsignedIndex.SetBinaryComparableKey(const keyvalue: qword; const key_target: PByte; var key_len: NativeInt; const is_null: boolean);
begin
  if not is_null then
    begin
      key_len := FFixedKeylen+1;
      case FFixedKeylen of
          1: PByte(@key_target[1])^     := Byte(keyvalue);
          2: PWord(@key_target[1])^     := SwapEndian(Word(keyvalue));
          4: PCardinal(@key_target[1])^ := SwapEndian(Cardinal(keyvalue));
          8: PQWord(@key_target[1])^    := SwapEndian(keyvalue);
        else
          raise EFRE_DB_PL_Exception.Create(edb_UNSUPPORTED,'unsupported fixed length in index transform to binary comparable');
      end;
      key_target[0] := 1; // 0 , val are ordered after NULL values which are prefixed by '0' not by '1'
    end
  else
    begin
      key_len := FFixedKeylen;
      FillByte(key_target[0],key_len,0);
    end;
end;

constructor TFRE_DB_UnsignedIndex.CreateStreamed(const stream: TStream; const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean; const unique_null: boolean);
begin
  Create(idx_name,fieldname,fieldtype,unique,collection,allow_null,unique_null);
  LoadIndex(stream,collection);
end;

procedure TFRE_DB_UnsignedIndex.FieldTypeIndexCompatCheck(fld: TFRE_DB_FIELD);
begin
  if not SupportsDataType(fld.FieldType) then
    raise EFRE_DB_PL_Exception.Create(edb_ILLEGALCONVERSION,'the unsigned index can only be used to index a unsigned number field, not a [%s] field.',[fld.FieldTypeAsString])
end;

function TFRE_DB_UnsignedIndex.SupportsDataType(const typ: TFRE_DB_FIELDTYPE): boolean;
begin
  case typ of
    fdbft_Byte,
    fdbft_UInt16,
    fdbft_UInt32,
    fdbft_UInt64,
    fdbft_Boolean,
    fdbft_GUID,
    fdbft_ObjLink,
    fdbft_DateTimeUTC: result := true;
    else result := false;
  end;
end;

function TFRE_DB_UnsignedIndex.IndexTypeTxt: String;
begin
  if FFixedKeylen=16 then
    result := 'uid/objectlink'
  else
    result := 'unsigned';
end;

procedure TFRE_DB_UnsignedIndex.ForAllIndexedUnsignedRange(const min, max: QWord; var guids: TFRE_DB_GUIDArray; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var lokey,hikey       : Array [0..8] of Byte;
    lokeylen,hikeylen : NativeInt;
    lokeyp,hikeyp     : PByte;

   procedure IteratorBreak(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var break : boolean);
   begin
     (FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore).AppendObjectUIDS(guids,ascending); // ForAllBreak(func,ascending,break);
   end;

begin
  if only_count_unique_vals=false then
    E_FOS_Implement;
  if FFixedKeylen = 16 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'no range queries on an uid or objectlink index are allowed');
  if not min_is_null then
    begin
      SetBinaryComparableKey(min,@lokey,lokeylen,min_is_null);
      lokeyp := lokey;
    end
  else
    lokeyp := nil;
  if not max_is_max then
    begin
      SetBinaryComparableKey(max,@hikey,hikeylen,max_is_max);
      hikeyp := hikey;
    end
  else
    hikeyp := nil;
  FIndex.RangeScan(lokeyp,hikeyp,lokeylen,hikeylen,@IteratorBreak,max_count,skipfirst,ascending)
end;

{ TFRE_DB_ChangeStep }

procedure TFRE_DB_ChangeStep.InternalWriteObject(const m: TMemoryStream; const obj: TFRE_DB_Object);
var nsize: NativeInt;
begin
   nsize := obj.NeededSize;
   m.WriteAnsiString(IntToStr(nsize));
   if (m.Size-m.Position)<(nsize) then
       m.SetSize(m.Size + nsize + 4096);
   obj.CopyToMemory(m.Memory+m.Position);
   m.Position:=m.Position+nsize;
end;

procedure TFRE_DB_ChangeStep.InternalReadObject(const m: TStream; var obj: TFRE_DB_Object);
var nsize    : NativeInt;
      mem    : Pointer;
      s      : string;
      stackm : Array [1..4096] of Byte;

begin
   s := m.ReadAnsiString;
   nsize  := FREDB_String2NativeInt(s);
   if nsize>4096 then
     Getmem(mem,nsize)
   else
     mem := @stackm[1];
   try
     m.ReadBuffer(mem^,nsize);
     obj := TFRE_DB_Object.CreateFromMemory(mem);
   finally
     if nsize>4096 then
       Freemem(mem);
   end;
end;

function TFRE_DB_ChangeStep.IsInsert: Boolean;
begin
  result := FIsStore;
end;

procedure TFRE_DB_ChangeStep.CheckExistence(const master: TFRE_DB_Master_Data);
begin

end;

procedure TFRE_DB_ChangeStep.WalReconstructionphase(const master: TFRE_DB_Master_Data);
begin

end;


class function TFRE_DB_ChangeStep.CreateFromWal(const wal: TStream): TFRE_DB_Changestep;
var stepheader : String;
    checkuid   : TGuid;
    coll       : TFRE_DB_NameType;
    new_obj    : TFRE_DB_Object;
    typ        : char;
    ttyp       : TFRE_DB_WAL_Step_Type;
    isstore    : boolean;

    function WAL_STEP_TYPE_FROM_CHAR(const hdr:char):TFRE_DB_WAL_Step_Type;
    begin
      for result in TFRE_DB_WAL_Step_Type do
        if CFRE_DB_WAL_Step_Type[result]=hdr then
          exit;
      raise EFRE_DB_PL_Exception.Create(edb_ERROR,'could not convert walsteptype [%s]',[hdr]);
    end;
begin
  stepheader := wal.ReadAnsiString;
  if (Length(stepheader)<1) then
       raise EFRE_DB_PL_Exception.Create(edb_ERROR,'step header bad');
  ttyp    := WAL_STEP_TYPE_FROM_CHAR(stepheader[1]);
  case ttyp of
      fdb_WAL_INSERT:
        begin
          isstore := StrToBool(stepheader[2]);
          checkuid := GFRE_BT.HexString_2_GUID(Copy(stepheader,3,32));
          coll     := Copy(stepheader,3+32,maxint);
          result := TFRE_DB_InsertStep.CreateAsWalReadBack(checkuid,coll,isstore,wal);
          //writeln('INSERT : ',stepheader,' ',(result as TFRE_DB_InsertStep).FNewObj.DumpToString());
          writeln('INSERT : ',stepheader,' ',(result as TFRE_DB_InsertStep).FNewObj.SchemeClass);
        end;
      fdb_WAL_UPDATE:
        begin
          isstore  := StrToBool(stepheader[2]);
          checkuid := GFRE_BT.HexString_2_GUID(Copy(stepheader,3,32));
          result   := TFRE_DB_UpdateStep.CreateAsWalReadBack(checkuid,isstore,wal);
         //writeln('INSERT : ',stepheader,' ',(result as TFRE_DB_InsertStep).FNewObj.DumpToString());
          writeln('UPDATE : ',stepheader,' ',(result as TFRE_DB_UpdateStep).upobj.SchemeClass)
        end;
      fdb_WAL_NEW_COLLECTION:
        begin
          result := TFRE_DB_NewCollectionStep.CreateAsWALReadBack(copy(stepheader,2,maxint));
          writeln('NEW COLLECTION  : ',stepheader)
        end;
      else
        begin
           raise EFRE_DB_PL_Exception.Create(edb_ERROR,'unimplemented transaction step header '+stepheader[2]);
        end;
    end;
end;

procedure TFRE_DB_ChangeStep.SetStepID(const id: NativeInt);
begin
  FStepID:=id;
end;

function TFRE_DB_ChangeStep.GetTransActionStepID: TFRE_DB_TransStepId;
begin
  result := FTransList.GetTransActionId+'/'+inttostr(FStepID);
end;

{ TREF_LinkEncapsulation }

//constructor TREF_LinkEncapsulation.Create(const links: TFRE_DB_GUIDArray);
//begin
//  FLinks := Copy(links);
//end;
//
//function TREF_LinkEncapsulation.Links: TFRE_DB_GUIDArray;
//begin
//  result := Copy(FLinks);
//end;


{ TFRE_DB_UpdateStep }

constructor TFRE_DB_UpdateStep.Create(obj, to_update_obj: TFRE_DB_Object; const is_insert: boolean);
begin
  SetLength(FSublist,25);
  FCnt          := 0;
  upobj         := obj;
  to_upd_obj    := to_update_obj;
  FIsStore     := is_insert;
end;

constructor TFRE_DB_UpdateStep.CreateAsWalReadBack(new_obj: TGuid; const is_store: boolean; const ws: TStream);
var i         : NativeInt;
    lbuffer   : Array [0..cG_Tuneable_LocalStackBuffer] of Byte;
    lMem      : Pointer;
    fieldname : TFRE_DB_NameType;
    size      : qword;

    procedure ReadBackField(var field:TFRE_DB_FIELD);
    begin
      if size>0 then
        try
          if size>=cG_Tuneable_LocalStackBuffer then
            begin
              Getmem(lMem,size);
            end
          else
            begin
              lmem := @lbuffer[0];
            end;
          ws.ReadBuffer(lMem^,size);
          TFRE_DB_FIELD.__ReadHeader(lMem,fieldname);
          field := TFRE_DB_FIELD.Create(nil,fdbft_NotFound,fieldname);
          field.CopyFieldFromMem(lMem,false);
        finally
          if size>=cG_Tuneable_LocalStackBuffer then
            Freemem(lMem);
        end;
    end;

begin
  FIsStore       := is_store;
  FIsWalReadBack := true;
  InternalReadObject(ws,upobj);
  if not FREDB_Guids_Same(upobj.UID,new_obj) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'read back wal updatestep failed, uids mismatch [%s<>[%s]',[GFRE_BT.GUID_2_HexString(upobj.UID),GFRE_BT.GUID_2_HexString(new_obj)]);

  fcnt := ws.ReadDWord;
  SetLength(FSublist,Fcnt);
  for i := 0 to FCnt-1 do
    with FSublist[i] do
      begin
        case ws.ReadByte of
          1 : FSublist[i].updtyp:=cev_FieldDeleted;
          2 : FSublist[i].updtyp:=cev_FieldAdded;
          3 : FSublist[i].updtyp:=cev_FieldChanged;
          else
            raise EFRE_DB_PL_Exception.Create(edb_ERROR,'invalid substep encoding');
        end;
        size := ws.ReadQWord;
        if size>0 then
          ReadBackField(newfield);
        size := ws.ReadQWord;
        if size>0 then
          ReadBackField(oldfield);
    end;

end;

procedure TFRE_DB_UpdateStep.AddSubStep(const uptyp: TFRE_DB_ObjCompareEventType; const new, old: TFRE_DB_FIELD);
begin
  if FCnt>=Length(FSublist) then
   SetLength(FSublist,Length(FSublist)+25);
  with FSublist[fcnt] do
    begin
      updtyp   := uptyp;
      newfield := new;
      oldfield := old;
      //Step     := self;
    end;
  inc(fcnt);
end;

function TFRE_DB_UpdateStep.HasNoChanges: Boolean;
begin
  result := FCnt=0;
end;

function TFRE_DB_UpdateStep.Needs_WAL: Boolean;
begin
  if upobj.IsVolatile then
    exit(false);
  result := true;
end;

procedure TFRE_DB_UpdateStep.WriteToWAL(const m: TMemoryStream);
var  i       : Integer;
     lbuffer : Array [0..cG_Tuneable_LocalStackBuffer] of Byte;
     lMem    : Pointer;
     size    : NativeInt;
     csize   : NativeInt;
begin
  m.WriteAnsiString(CFRE_DB_WAL_Step_Type[fdb_WAL_UPDATE]+BoolToStr(FIsStore,'1','0')+upobj.UID_String);
  InternalWriteObject(m,upobj);
  m.WriteDWord(FCnt);
  for i := 0 to FCnt-1 do
    begin
      with FSublist[i] do
        begin
          case updtyp of
            cev_FieldDeleted: m.WriteByte(1);
            cev_FieldAdded:   m.WriteByte(2);
            cev_FieldChanged: m.WriteByte(3);
          end;
          if Assigned(newfield) then
            begin
              size := newfield.GetStreamingSize;
              m.WriteQWord(size);
              if size < cG_Tuneable_LocalStackBuffer then
                begin
                  lmem := @lbuffer[0];
                  csize := newfield.CopyFieldToMem(lmem);
                  if csize<>size then
                    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'internal field stream sice error [%d<>%d]',[size,csize]);
                  m.WriteBuffer(lMem^,size);
                end
              else
                begin
                  Getmem(lMem,size);
                  try
                   csize := newfield.CopyFieldToMem(lMem);
                   if csize<>size then
                     raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'internal field stream sice error [%d<>%d]',[size,csize]);

                    m.WriteBuffer(lMem^,size);
                  finally
                    Freemem(lMem);
                  end;
                end;
            end
          else
            m.WriteQWord(0);
          if Assigned(oldfield) then
            begin
              size := oldfield.GetStreamingSize;
              m.WriteQWord(size);
              if size < cG_Tuneable_LocalStackBuffer then
                begin
                  lmem := @lbuffer[0];
                  oldfield.CopyFieldToMem(lmem);
                end
              else
                begin
                  Getmem(lMem,size);
                  try
                    oldfield.CopyFieldToMem(lMem);
                  finally
                    Freemem(lMem);
                  end;
                end;
            end
          else
            m.WriteQWord(0);
        end;
    end;
end;


//Check what has to be done at master level, (reflinks)
procedure TFRE_DB_UpdateStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
var i,j       : NativeInt;
    collarray : IFRE_DB_PERSISTANCE_COLLECTION_ARRAY;
begin
  for i:=0 to FCnt-1 do
    with FSublist[i] do
      begin
        collarray := to_upd_obj.__InternalGetCollectionList;
        for j := 0 to high(collarray) do
          collarray[j].GetPersLayerIntf.UpdateInThisColl(newfield,oldfield,to_upd_obj,upobj,updtyp,check);
      end
end;

procedure TFRE_DB_UpdateStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
var i,j       : NativeInt;
    collarray : IFRE_DB_PERSISTANCE_COLLECTION_ARRAY;

    procedure _DeletedField;
    begin
      with FSublist[i] do
        begin
          to_upd_obj.Set_Store_Locked(false);
          try
            case oldfield.FieldType of
              fdbft_Object:
                begin
                  writeln('MASTERSTORE ABORT 1');
                  abort;
                  master.DeleteObject(newfield.AsObject.UID,check);
                end;
              fdbft_ObjLink:
                begin
                  writeln('MASTERSTORE ABORT 2');
                  abort;
                  master._RemoveRefLinkFieldDelRefs(to_upd_obj,newfield,check);
                end;
              else begin
                if not check then
                  to_upd_obj.DeleteField(oldfield.FieldName);
              end; // ok
            end;
          finally
            to_upd_obj.Set_Store_Locked(true);
          end;
        end;
    end;

    procedure _AddedField;
    var sc,fn : TFRE_DB_NameType;
        j     : nativeint;
    begin
      with FSublist[i] do
        case newfield.FieldType of
          fdbft_NotFound,fdbft_GUID,fdbft_Byte,fdbft_Int16,fdbft_UInt16,fdbft_Int32,fdbft_UInt32,fdbft_Int64,fdbft_UInt64,
          fdbft_Real32,fdbft_Real64,fdbft_Currency,fdbft_String,fdbft_Boolean,fdbft_DateTimeUTC,fdbft_Stream :
            begin
             // Just add the Field
              if check then
                exit;
              to_upd_obj.Set_Store_Locked(false);
              try
                to_upd_obj.Field(newfield.FieldName).CloneFromField(newfield);
              finally
                to_upd_obj.Set_Store_Locked(true);
              end;
            end;
          fdbft_Object:
            begin
              if check then
                exit;
              to_upd_obj.Field(newfield.FieldName).AsObject := newfield.AsObject;
            end;
          fdbft_ObjLink:
            begin
              to_upd_obj.Set_Store_Locked(false);
              try
                if check then
                  begin
                    for j:=0 to high(newfield.AsObjectLinkArray) do
                      master.__CheckReferenceLink(to_upd_obj,newfield.FieldName,newfield.AsObjectLinkArray[j],sc);
                  end
                else
                  begin
                    fn := uppercase(newfield.FieldName)+'>'+uppercase(to_upd_obj.SchemeClass);
                    for j:=0 to high(newfield.AsObjectLinkArray) do
                      begin
                        master.__CheckReferenceLink(to_upd_obj,newfield.FieldName,newfield.AsObjectLinkArray[j],sc);
                        master.__SetupInitialRefLink(to_upd_obj,fn,sc,newfield.AsObjectLinkArray[j]);
                      end;
                    to_upd_obj.Field(newfield.FieldName).AsObjectLinkArray:=newfield.AsObjectLinkArray;
                  end;
              finally
                to_upd_obj.Set_Store_Locked(true);
              end;
            end;
        end;
    end;

    procedure _ChangedField;
    var sc,fn : TFRE_DB_NameType;
        j     : nativeint;
    begin
      with FSublist[i] do
        case newfield.FieldType of
          fdbft_NotFound,fdbft_GUID,fdbft_Byte,fdbft_Int16,fdbft_UInt16,fdbft_Int32,fdbft_UInt32,fdbft_Int64,fdbft_UInt64,
          fdbft_Real32,fdbft_Real64,fdbft_Currency,fdbft_String,fdbft_Boolean,fdbft_DateTimeUTC,fdbft_Stream :
            begin
              if check then
                exit;
              to_upd_obj.Set_Store_Locked(false);
              try
                to_upd_obj.Field(newfield.FieldName).CloneFromField(newfield);
              finally
                to_upd_obj.Set_Store_Locked(true);
              end;
            end;
          fdbft_Object:
            begin
              if check then
                exit;
              writeln('CHANGE OBJECT - (FIELD) ',check,' ',oldfield.ValueCount,'  ',newfield.ValueCount);
              to_upd_obj.Set_Store_Locked(false);
              try
                to_upd_obj.Field(newfield.FieldName).AsObjectArr := newfield.AsObjectArr;
              finally
                to_upd_obj.Set_Store_Locked(true);
              end;
            end;
          fdbft_ObjLink:
            begin
              to_upd_obj.Set_Store_Locked(false);
              try
                if check then
                  begin
                    for j:=0 to high(newfield.AsObjectLinkArray) do
                      master.__CheckReferenceLink(to_upd_obj,newfield.FieldName,newfield.AsObjectLinkArray[i],sc);
                  end
                else
                  begin
                    master._ChangeRefLink(to_upd_obj,newfield.FieldName,newfield.AsObjectLinkArray);
                    to_upd_obj.Field(newfield.FieldName).AsObjectLinkArray:=newfield.AsObjectLinkArray;
                  end;
              finally
                to_upd_obj.Set_Store_Locked(true);
              end;
            end;
        end;
    end;

begin
  if to_upd_obj.IsObjectRoot then
    if length(to_upd_obj.__InternalGetCollectionList)=0 then
      raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'must have internal collections to store into');
  for i:=0 to FCnt-1 do
    begin
      with FSublist[i] do
        case updtyp of
          cev_FieldDeleted:
            _DeletedField;
          cev_FieldAdded:
            _AddedField;
          cev_FieldChanged:
            _ChangedField;
        end;
    end;
end;

{ TFRE_DB_DeleteSubObjectStep }

constructor TFRE_DB_DeleteSubObjectStep.Create(var del_obj: TFRE_DB_Object; const from_coll: TFRE_DB_NameType; const is_store: boolean);
begin
  FDelObj   := del_obj;
  FIsStore  := is_store;
  FObjPtr   := @del_obj;
  CollName  := from_coll;
end;

function TFRE_DB_DeleteSubObjectStep.Needs_WAL: Boolean;
begin
  if FDelObj.IsVolatile then
    exit(false);
  if not FDelObj.IsObjectRoot then
    exit(false);
  result := true;
end;

procedure TFRE_DB_DeleteSubObjectStep.WriteToWAL(const m: TMemoryStream);
begin
   m.WriteAnsiString(CFRE_DB_WAL_Step_Type[fdb_WAL_DELETE_SUB_OBJECT]+BoolToStr(FIsStore,'1','0')+FDelObj.UID_String+CollName);
end;

procedure TFRE_DB_DeleteSubObjectStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
var arr : IFRE_DB_PERSISTANCE_COLLECTION_ARRAY;
      i : NativeInt;
begin
  assert(IsInsert=false);
  if check then
    exit;
  if FDelObj.IsObjectRoot then // TDOD -> CHECK, make it working
    begin
      arr := FDelObj.__InternalGetCollectionList;
      for i := 0 to high(arr) do
        arr[i].GetPersLayerIntf.DeleteFromThisColl(FDelObj,check);
    end;
end;

procedure TFRE_DB_DeleteSubObjectStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);
begin
  writeln('*****DELETE STEP .... ReMOVINg : ',FDelObj.UID_String);
  assert(IsInsert=false);
  master.DeleteObject(FDelObj.UID,check);
  if not check  then
    FObjPtr^:=nil;
end;

{ TFRE_DB_TransactionalUpdateList }

function     ChangeStepNull        (const cs : PFRE_DB_ChangeStep):boolean;
begin
  result := not assigned(cs^);
end;

function     ChangeStepSame        (const cs1,cs2 : PFRE_DB_ChangeStep):boolean;
begin
  result := cs1^=cs2^;
end;

constructor TFRE_DB_TransactionalUpdateList.Create(const TransID: TFRE_DB_NameType; const master_data: TFRE_DB_Master_Data);
begin
  FTransId := TransID;
  FChangeList.InitSparseList(nil,@ChangeStepNull,@ChangeStepSame,10);
  FMaster  := master_data;
  FWalMem  := TMemoryStream.Create;
end;

procedure TFRE_DB_TransactionalUpdateList.ReadFromBackWalStream(const walstream: TStream);
var Cnt,i   : NativeInt;
    idcheck : string;

begin
  FTransId := walstream.ReadAnsiString;
  Cnt     := FREDB_String2NativeInt(walstream.ReadAnsiString);
  for i := 1 to Cnt do
    begin
      AddChangeStep(TFRE_DB_ChangeStep.CreateFromWal(walstream));
    end;
  idcheck := walstream.ReadAnsiString;
  if FTransId+'#!'<>idcheck then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'wals stream bad transactions dont match [''%s'' <> ''%s'']',[idcheck,FTransId]);
end;


function TFRE_DB_TransactionalUpdateList.AddChangeStep(const step: TFRE_DB_ChangeStep): NativeInt;
begin
  step.FTransList := self;
  result          := FChangeList.Add(step);
  step.SetStepID(result);
end;


function     ObjectGuidCompare     (const o1,o2 : PFRE_DB_Object):boolean;
begin
  result := FREDB_Guids_Same(o1^.UID,o2^.UID);
end;

function     DBObjIsNull           (const obj   : PFRE_DB_Object) : Boolean;
begin
  result := not assigned(obj^);
end;

procedure TFRE_DB_TransactionalUpdateList.GenerateAnObjChangeList(const store: boolean; const obj: TFRE_DB_Object; const collection_name: TFRE_DB_NameType);
var deleted_obj   : OFRE_SL_TFRE_DB_Object;
    inserted_obj  : OFRE_SL_TFRE_DB_Object;
    updated_obj   : OFRE_SL_TFRE_DB_Object;
    coll          : IFRE_DB_PERSISTANCE_COLLECTION;
    to_update_obj : TFRE_DB_Object;
    i             : NativeInt;

    procedure WriteGuid(var o : TFRE_DB_Object ; const idx : NativeInt; var halt:boolean);
    begin
      write(idx,' ',o.UID_String,',');
    end;

    //function ObjectGuidCompare(const o1,o2:TFRE_DB_Object):boolean;
    //begin
    //  result := FREDB_Guids_Same(o1.UID,o2.UID);
    //end;

    procedure SearchInOldAndRemoveExistingInNew(var o : TFRE_DB_Object ; const idx : NativeInt ; var halt: boolean);
    begin
      if deleted_obj.Exists(o)<>-1 then
        begin
          updated_obj.Add(o);
          inserted_obj.ClearIndex(idx);
        end
    end;

    procedure SearchInUpdatesAndRemoveExistingFromOld(var o : TFRE_DB_Object ; const idx : NativeInt ; var halt: boolean);
    var ex : NativeInt;
    begin
      if updated_obj.Exists(o)<>-1 then
        deleted_obj.ClearIndex(idx);
    end;

    procedure GenerateUpdates(var new_object : TFRE_DB_Object ; const idx : NativeInt ; var halt: boolean);
    var child      : TFRE_DB_Object;
        updatestep : TFRE_DB_UpdateStep;

        procedure CompareEvent (const obj:TFRE_DB_Object ; const compare_event : TFRE_DB_ObjCompareEventType ; const new_fld,old_field:TFRE_DB_FIELD);
        begin
          case compare_event of
            cev_FieldDeleted:
                updatestep.addsubstep(cev_FieldDeleted,nil,old_field);
            cev_FieldAdded:
                updatestep.addsubstep(cev_FieldAdded,new_fld,nil);
            cev_FieldChanged :
                updatestep.addsubstep(cev_FieldChanged,new_fld,old_field);
          end;
        end;

    begin
      if not FMaster.ExistsObject(new_object.UID) then
        begin
          writeln('DEBUG EXISTS CHECK UPDATE FAILED ',new_object.UID_String,' ',store);
          system.halt();
        end;
      if new_object.IsObjectRoot then
        begin
          updatestep := TFRE_DB_UpdateStep.Create(new_object,to_update_obj,store);
          new_object.__InternalCompareToObj(to_update_obj,@CompareEvent);
        end
      else
        begin
          child      := to_update_obj.FetchObjByUID(new_object.UID);
          assert(assigned(child));
          updatestep := TFRE_DB_UpdateStep.Create(new_object,child,store);
          new_object.__InternalCompareToObj(child,@CompareEvent);
        end;
      if updatestep.HasNoChanges then
        updatestep.Free
      else
        begin
          self.AddChangeStep(updatestep);
          //writeln(updatestep.DescribeText);
        end;
         //FTransaction.PostProcessUpdateStep(updatestep);
    end;

    procedure GenerateInserts(var new_object : TFRE_DB_Object ; const idx : NativeInt ; var halt: boolean);
    begin
      if new_object.IsObjectRoot then
        self.AddChangeStep(TFRE_DB_InsertStep.Create(new_object,coll,store))
      else
        self.AddChangeStep(TFRE_DB_InsertSubStep.Create(new_object,coll,store));
      if store then
        halt := true; // In insert case only generate an insert for the root object
      abort;
    end;

    procedure GenerateDeletes(var del_object : TFRE_DB_Object ; const idx : NativeInt ; var halt: boolean);
    begin
      if not FMaster.ExistsObject(del_object.UID) then
        begin
          writeln('EXISTS CHECK DELETE FAILED ');
          system.halt;
        end;
      assert(not del_object.IsObjectRoot);
      self.AddChangeStep(TFRE_DB_DeleteSubObjectStep.Create(del_object,collection_name,store));
    end;
begin
  if store then
    begin
      to_update_obj := nil;
      if collection_name='' then
        raise EFRE_DB_PL_Exception.Create(edb_INVALID_PARAMS,'a collectionname must be provided on store request');
      if not FMaster.MasterColls.GetCollection(collection_name,coll) then
        raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'the specified collection [%s] was not found',[collection_name]);
    end
  else
    begin
       if not FMaster.FetchObject(obj.UID,to_update_obj,true) then
         raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'an object should be updated but was not found [%s]',[obj.UID_String]);
       coll := nil;
       //SetLength(notify_collections,Length(to_update_obj.__InternalGetCollectionList));
       //for i := 0 to high(notify_collections) do
       //  notify_collections[i] := to_update_obj.__InternalGetCollectionList[i].CollectionName();
       //if Length(notify_collections)=0 then
       //  raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'lenght of internalcollections for object [%s] is empty, on update case !',[to_update_obj.UID_String]);
       if collection_name<>'' then
         begin
           if not FMaster.MasterColls.GetCollection(collection_name,coll) then
             raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'the collectionname [%s] specified for an update request, does not exist',[collection_name]);
           //TODO Check if update object has Collection
           //TODO Check if collection has updateobject
         end;
       to_update_obj.Set_Store_Locked(false);
    end;
  try
    deleted_obj.InitSparseList(nil,@DBObjIsNull,@ObjectGuidCompare,25);
    inserted_obj.InitSparseList(nil,@DBObjIsNull,@ObjectGuidCompare,25);
    updated_obj.InitSparseList(nil,@DBObjIsNull,@ObjectGuidCompare,25);
    //if assigneD(to_update_obj) then
      //to_update_obj.Field('pemper').AsString:='faker';
    //to_update_obj.Field('TEST').AsString:='fuuker';
    //to_update_obj.FieldPath('desc.txt').AsString:='ChangedChanged';
    //to_update_obj.DeleteField('desc');
    //obj.DeleteField('desc');

    //writeln('--- OLD OBJECT ----');
    //if assigned(to_update_obj) then
    //  writeln(to_update_obj.DumpToString());
    //writeln('--- NEW OBJECT -----');
    //writeln(obj.DumpToString());
    //writeln('------------');

    if assigned(to_update_obj) then // update case
      to_update_obj.__InternalGetFullObjectList(deleted_obj);
    obj.__InternalGetFullObjectList(inserted_obj);
  //
  //      writeln('------------------------');
  //      writeln(' STEP A');
  //      write('DELETED  LIST [');deleted_obj.ForAllBreak(@WriteGuid);writeln('] ',deleted_obj.Count);
  //      write('INSERTED LIST [');inserted_obj.ForAllBreak(@WriteGuid);writeln('] ',inserted_obj.Count);
  //      writeln('STEP B');
  //      writeln('------------------------');

    // Yields the updated_obj in the updatelist and the inserts in the newlist, all objects come from the "new non persitent object copy"
    inserted_obj.ForAllBreak(@SearchInOldAndRemoveExistingInNew);
    // Yields the deletes in the oldlist, all objects in this are from the "old, stored persitent object"
    deleted_obj.ForAllBreak(@SearchInUpdatesAndRemoveExistingFromOld);

    //write('DELETED  LIST [');deleted_obj.ForAllBreak(@WriteGuid);writeln('] ',deleted_obj.Count);
    //write('INSERTED LIST [');inserted_obj.ForAllBreak(@WriteGuid);writeln('] ',inserted_obj.Count);
    //write('UPDATED  LIST [');updated_obj.ForAllBreak(@WriteGuid);writeln('] ',updated_obj.Count);

    if deleted_obj.Count>0 then
      deleted_obj.ForAllBreak(@GenerateDeletes);
    if inserted_obj.Count>0 then
      inserted_obj.ForAllBreak(@GenerateInserts);
    if updated_obj.Count>0 then
      updated_obj.ForAllBreak(@GenerateUpdates);
  finally
    if assigned(to_update_obj) then
      to_update_obj.Set_Store_Locked(true);
  end;
end;

function TFRE_DB_TransactionalUpdateList.GetTransActionId: TFRE_DB_NameType;
begin
  result := FTransId;
end;

function TFRE_DB_TransactionalUpdateList.GetTransLastStepTransId: TFRE_DB_TransStepId;
begin
  //result := FChangeList.;
end;

function TFRE_DB_TransactionalUpdateList.GetNotifyIF: IFRE_DB_DBChangedNotification;
begin
  result := FNotifyIf;
end;

procedure TFRE_DB_TransactionalUpdateList.ProcessCheck(const WAL_RepairMode: boolean);
var failure : boolean;


  procedure WalReconstruction(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    with step do
      WalReconstructionphase(FMaster);
  end;

  procedure CheckForExistence(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    with step do
      CheckExistence(FMaster);
  end;

  procedure StoreInCollectionCheck(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    with step do
      ChangeInCollectionCheckOrDo(FMaster,true);
  end;

  procedure MasterStoreCheck(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    with step do
      MasterStore(FMaster,true);
  end;

  procedure NeedsWalCheck(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    if step.Needs_WAL then
      begin
        FNeedsWal := true;
        halt_flag := true;
      end;
  end;

begin
  failure   := false;
  FNeedsWAL := false;
  if WAL_RepairMode then
    FChangeList.ForAllBreak(@WalReconstruction);
  FChangeList.ForAllBreak(@CheckForExistence);
  FChangeList.ForAllBreak(@StoreInCollectionCheck);
  FChangeList.ForAllBreak(@MasterStoreCheck);
  FChangeList.ForAllBreak(@NeedsWalCheck);
end;


function TFRE_DB_TransactionalUpdateList.Write_WAL_Or_DCC(const Layer: IFRE_DB_PERSISTANCE_LAYER): boolean;
var TransID:String;

  procedure WriteWAL(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    step.WriteToWal(FWalMem);
  end;

begin
  result := true;
  if FChangeList.Count=0 then
    exit(false);
    //raise EFRE_DB_PL_Exception.Create(edb_NO_CHANGE,'TRANSACTIONAL COMMIT FAILED, CHANGELIST EMPTY');
  if FNeedsWAL then
    begin
      FWalMem.Position := 0;
      TransID := FMaster.FetchNewTransactionID(FTransId);
      FWalMem.WriteAnsiString(TransID);
      FWalMem.WriteAnsiString(IntToStr(FChangeList.Count));
      FChangeList.ForAllBreak(@WriteWal);
      FWalMem.WriteAnsiString(TransID+'#!');
      Layer.SyncWriteWAL(FWalMem);
    end;
end;

function TFRE_DB_TransactionalUpdateList.Commit(const Layer: IFRE_DB_PERSISTANCE_LAYER; const WAL_RepairMode: boolean): boolean;
var changes : boolean;

  procedure StoreInCollection(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    step.ChangeInCollectionCheckOrDo(FMaster,false);
    if step is TFRE_DB_InsertStep then
      halt_flag:=true;
  end;

  //Store objects and sub objects
  procedure MasterStore(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    step.MasterStore(FMaster,false);
  end;

begin
  { Perform all necessary prechecks before changing the Database }
  ProcessCheck(WAL_RepairMode);

  { Write the WAL Log }
  if not WAL_RepairMode then
    changes := Write_WAL_Or_DCC(Layer);

  { Apply the changes, and record the Notifications }
  if changes then
    begin
      FChangeList.ForAllBreak(@StoreInCollection);
      FChangeList.ForAllBreak(@MasterStore);
    end
  else
   changes:=changes;
  result := changes;
end;

procedure TFRE_DB_TransactionalUpdateList.Rollback;
begin
  abort;
end;

destructor TFRE_DB_TransactionalUpdateList.Destroy;
  procedure CleanUp(var step:TFRE_DB_ChangeStep;const idx:NativeInt ; var halt_flag:boolean);
  begin
    step.Free;
  end;
begin
  FWalMem.Free;
  FChangeList.ForAllBreak(@Cleanup);
end;

{ TFRE_DB_InsertStep }

constructor TFRE_DB_InsertStep.Create(new_obj: TFRE_DB_Object; const coll: IFRE_DB_PERSISTANCE_COLLECTION; const is_store: boolean);
var cn:string;
begin
  FNewObj   := new_obj;
  FColl     := coll;
  FIsStore  := is_store;
  assert(assigned(FNewObj.Parent));
end;

constructor TFRE_DB_InsertStep.CreateAsWalReadBack(new_obj: TGuid; const coll: TFRE_DB_NameType; const is_store: boolean; const ws: TStream);
begin
  FIsStore       := is_store;
  FCollName      := coll;
  FIsWalReadBack := true;
  InternalReadObject(ws,FNewObj);
  if not FREDB_Guids_Same(FNewObj.UID,new_obj) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'read back wal insertstep failed, uids mismatch [%s<>[%s]',[GFRE_BT.GUID_2_HexString(FNewObj.UID),GFRE_BT.GUID_2_HexString(new_obj)]);
end;

function TFRE_DB_InsertStep.IsARootInsert: Boolean;
begin
  result := not assigned(FNewObj.Parent);
end;

function TFRE_DB_InsertStep.Needs_WAL: Boolean;
begin
  if FNewObj.IsVolatile then
    exit(false);
  if not IsARootInsert then // Only root objects need to be in WAL
    exit(false);
  result := true;
end;


function TFRE_DB_InsertStep.CheckExistence(const master: TFRE_DB_Master_Data; const raise_ex: boolean): TFRE_DB_Errortype;
begin
  if master.ExistsObject(FNewObj.UID) then
    if raise_ex then
      raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'the obj [%s] does already exist in master data.')
    else
      exit(edb_EXISTS);
  result := edb_OK;
end;

procedure TFRE_DB_InsertStep.ChangeInCollectionCheckOrDo(const master: TFRE_DB_Master_Data; const check: boolean);
begin
  //writeln('********** INSERT CHECK ',FNewObj.UID_String,' ',FNewObj.ClassName,'  ',IsARootInsert);
  //writeln(FNewObj.DumpToString());
  //writeln('********** INSERT CHECK ',FNewObj.UID_String,' ',FNewObj.ClassName,'  ',IsARootInsert);
  if FIsWalReadBack then
    if not FTransList.FMaster.MasterColls.GetCollection(FCollName,FColl) then
      raise EFRE_DB_PL_Exception.Create(edb_ERROR,'insert step, wal repair collection [%s] does not exist!',[FCollName]);

  if IsARootInsert then
    FColl.GetPersLayerIntf.StoreInThisColl(FNewObj,check)
  else
    begin
       //TODO think about child objects storing in other collections
      if IsInsert then
        begin
          raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'ONLY ROOT OBJECTS CAN BE INSERTED CURRENTLY');
        end
      else
        begin

        end;
    end;
end;

procedure TFRE_DB_InsertStep.MasterStore(const master: TFRE_DB_Master_Data; const check: boolean);

  procedure MasterStoreAndSubObjects(const obj:TFRE_DB_Object; var halt:boolean);
  begin
    //writeln('ROOT OBJECT - MASTER STORE :: ',obj.InternalUniqueDebugKey,' IS INSERT ',IsInsert);
    master.StoreObject(obj,check);
  end;

begin
  if FNewObj.IsObjectRoot then
    begin
      assert((check=true) or (length(FNewObj.__InternalGetCollectionList)>0));
      FNewObj.ForAllObjectsBreakHierarchic(@MasterStoreAndSubObjects)
    end
  else
    begin
      //writeln('CHILD OBJECT (alone) - MASTER STORE :: ',FNewObj.InternalUniqueDebugKey,' IS INSERT ',IsInsert);
      master.StoreObject(FNewObj,check);
    end;
end;


procedure TFRE_DB_InsertStep.WriteToWAL(const m: TMemoryStream);
begin
  if FIsStore=false then
    FIsStore:=FIsStore;
  assert(FIsStore=true);
  m.WriteAnsiString(CFRE_DB_WAL_Step_Type[fdb_WAL_INSERT]+BoolToStr(FIsStore,'1','0')+FNewObj.UID_String+FColl.CollectionName);
  InternalWriteObject(m,FNewObj);
end;


{ TFRE_DB_IndexValueStore }

procedure TFRE_DB_IndexValueStore.InternalCheck;
var i:NativeInt;
begin
  //try
  //  for i:=0 to high(FOBJArray) do
  //    FOBJArray[i].Assert_CheckStoreLocked;
  //except on e:Exception do
  // begin
  //  writeln('E ',e.Message);
  //  writeln('LEN ARRAY ',Length(FOBJArray));
  //  for i:=0 to high(FOBJArray) do
  //    begin
  //      writeln('--',i,' ',FOBJArray[i].InternalUniqueDebugKey);
  //      writeln(FOBJArray[i].DumpToString());
  //      writeln('--');
  //    end;
  //  raise;
  // end;
  //end;
end;


function TFRE_DB_IndexValueStore.Exists(const guid: TGUID): boolean;
var i : NativeInt;
begin
  for i := 0 to High(FOBJArray) do
    if FREDB_Guids_Compare(FOBJArray[i],guid)=0 then
      exit(true);
  result := false;
end;

function TFRE_DB_IndexValueStore.Add(const objuid: TGuid): boolean;
begin
  if Exists(objuid) then
    exit(false);
  SetLength(FOBJArray,Length(FOBJArray)+1);
  FOBJArray[high(FOBJArray)] := objuid;
  result := true;
end;


//function TFRE_DB_IndexValueStore.IndexedObjects: TFRE_DB_ObjectArray;
//begin
//  result := FOBJArray;
//  InternalCheck;
//end;

procedure TFRE_DB_IndexValueStore.StreamToThis(const stream: TStream);
var i : NativeInt;
begin
  stream.WriteQWord(Length(FOBJArray));
  for i:=0 to high(FOBJArray) do
    stream.WriteBuffer(FOBJArray[i],SizeOf(TGuid));
end;

procedure TFRE_DB_IndexValueStore.LoadFromThis(const stream: TStream; const coll: IFRE_DB_PERSISTANCE_COLLECTION);
var i,cnt : NativeInt;
    uid   : TGUID;
    obj   : TFRE_DB_Object;
begin
  cnt := stream.ReadQWord;
  SetLength(FOBJArray,cnt);
  for i:=0 to high(FOBJArray) do
    begin
      stream.ReadBuffer(uid,SizeOf(TGuid));
      FOBJArray[i] := uid;
      if not coll.GetPersLayerIntf.FetchIntFromColl(uid,obj) then //
        raise EFRE_DB_PL_Exception.Create(edb_ERROR,'STREAM LOAD INDEX ERROR CANT FIND [%s] IN COLLECTION',[GFRE_BT.GUID_2_HexString(uid)]);
    end;
end;

//procedure TFRE_DB_IndexValueStore.ForAll(const func: IFRE_DB_Obj_Iterator; const ascending: boolean);
//var i   : NativeInt;
//    obj : TFRE_DB_Object;
//
//    procedure CloneOutIndex(const idx : NativeInt);
//    begin
//      obj := FOBJArray[i];
//      obj.Assert_CheckStoreLocked;
//      obj.Set_Store_Locked(false);
//      try
//        func(obj.CloneToNewObject());
//      finally
//        obj.Set_Store_Locked(true);
//      end;
//    end;
//
//begin
//  if ascending then
//    for i := 0 to High(FOBJArray) do
//      CloneOutIndex(i)
//  else
//    for i := High(FOBJArray) downto 0 do
//      CloneOutIndex(i);
//end;

function TFRE_DB_IndexValueStore.ObjectCount: NativeInt;
begin
  result := Length(FOBJArray);
end;

procedure TFRE_DB_IndexValueStore.AppendObjectUIDS(var uids: TFRE_DB_GUIDArray; const ascending: boolean);
var i,pos : NativeInt;
begin
  pos := Length(uids);
  SetLength(uids,Length(uids)+ObjectCount);
  if ascending then
    for i := 0 to high(FOBJArray) do
      begin
        uids[pos] := FOBJArray[i];
        inc(pos);
      end
  else
    for i := high(FOBJArray) downto 0 do
      begin
        uids[pos] := FOBJArray[i];
        inc(pos);
      end;
end;

function TFRE_DB_IndexValueStore.RemoveUID(const guid: TGUID): boolean;
var i        : NativeInt;
    newarray : TFRE_DB_GUIDArray;
    cnt      : NativeInt;
begin
  SetLength(newarray,high(FOBJArray));
  cnt    := 0;
  result := false;
  for i := 0 to High(FOBJArray) do
    if FOBJArray[i]<>guid then
      begin
        newarray[cnt] := FOBJArray[i];
        inc(cnt);
      end
    else
      result := true;
  FOBJArray := newarray;
end;

//procedure TFRE_DB_IndexValueStore.ForAllBreak(const func: IFRE_DB_Obj_IteratorBreak; const ascending: boolean; var halt: boolean);
//var i    : NativeInt;
//    obj  : TFRE_DB_Object;
//
//    procedure CloneOutIndex(const idx : NativeInt ; var halt:boolean);
//    begin
//      obj := FOBJArray[i];
//      obj.Assert_CheckStoreLocked;
//      obj.Set_Store_Locked(false);
//      try
//        halt := func(obj.CloneToNewObject());
//      finally
//        obj.Set_Store_Locked(true);
//      end;
//    end;
//
//begin
//  if ascending then
//    for i := 0 to High(FOBJArray) do
//      begin
//        CloneOutIndex(i,halt);
//        if halt then
//            break;
//      end
//  else
//    for i := High(FOBJArray) downto 0 do
//      begin
//        CloneOutIndex(i,halt);
//        if halt then
//            break;
//      end;
//end;

constructor TFRE_DB_IndexValueStore.create;
begin
  inherited;
end;

destructor TFRE_DB_IndexValueStore.Destroy;
begin
  inherited Destroy;
end;

{ TFRE_DB_Master_Data }


function TFRE_DB_Master_Data.GetOutBoundRefLinks(const from_obj: TGUID): TFRE_DB_ObjectReferences;
var key : RFRE_DB_GUID_RefLink_InOut_Key;
    cnt : NativeInt;

   procedure Iterate(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var halt : boolean);
   var namelen : NativeInt;
       name    : TFRE_DB_NameType;
   begin
     if cnt=Length(result) then
       SetLength(result,Length(result)+10);
     assert(value=$BAD0BEEF);
     namelen := KeyLen-33;
     Assert(namelen>0);
     SetLength(name,namelen);
     move(PFRE_DB_GUID_RefLink_In_Key(key)^.SchemeSepField,name[1],namelen); // copy name
     result[cnt].fieldname  := GFRE_BT.SepLeft(name,'>');
     result[cnt].schemename := GFRE_BT.SepRight(name,'>');
     move(PFRE_DB_GUID_RefLink_In_Key(key)^.ToFromGuid,result[cnt].linked_uid,16); // copy guid
     inc(cnt);
   end;

begin
  cnt := 0;
  move(from_obj,key.GUID,16);
  key.RefTyp:=$99;
  FMasterRefLinks.PrefixScan(@key,17,@Iterate);
  SetLength(result,cnt);
end;

function TFRE_DB_Master_Data.GetInboundLinks(const to_obj: TGUID): TFRE_DB_ObjectReferences;
var key : RFRE_DB_GUID_RefLink_InOut_Key;
    cnt : NativeInt;

   procedure Iterate(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var halt : boolean);
   var namelen : NativeInt;
       name    : TFRE_DB_NameType;
   begin
     if cnt=Length(result) then
       SetLength(result,Length(result)+10);
     assert(value=$BEEF0BAD);
     namelen := KeyLen-33;
     Assert(namelen>0);
     SetLength(name,namelen);
     move(PFRE_DB_GUID_RefLink_In_Key(key)^.SchemeSepField,name[1],namelen); // copy name
     result[cnt].fieldname  := GFRE_BT.SepRight(name,'<');
     result[cnt].schemename := GFRE_BT.SepLeft(name,'<');
     move(PFRE_DB_GUID_RefLink_In_Key(key)^.ToFromGuid,result[cnt].linked_uid,16); // copy guid
     inc(cnt);
   end;

begin
  cnt := 0;
  move(to_obj,key.GUID,16);
  key.RefTyp:=$AA;
  FMasterRefLinks.PrefixScan(@key,17,@Iterate);
  SetLength(result,cnt);
end;

procedure TFRE_DB_Master_Data.__SetupOutboundLinkKey(const from_uid, to_uid: TFRE_DB_GUID; const scheme_link_key: TFRE_DB_NameTypeRL; var refoutkey: RFRE_DB_GUID_RefLink_InOut_Key);
begin
  move(from_uid,refoutkey.GUID,16);
  refoutkey.RefTyp := $99;
  move(to_uid,refoutkey.ToFromGuid,16);
  move(scheme_link_key[1],refoutkey.SchemeSepField,Length(scheme_link_key));
  refoutkey.KeyLength := 33+Length(scheme_link_key);
end;

procedure TFRE_DB_Master_Data.__SetupInboundLinkKey(const from_uid, to_uid: TFRE_DB_GUID; const scheme_link_key: TFRE_DB_NameTypeRL; var refinkey: RFRE_DB_GUID_RefLink_InOut_Key);
begin
  move(to_uid,refinkey.GUID,16);
  refinkey.RefTyp := $AA;
  move(from_uid,refinkey.ToFromGuid,16);
  move(scheme_link_key[1],refinkey.SchemeSepField,length(scheme_link_key));
  refinkey.KeyLength := 33+Length(scheme_link_key);
end;

function TFRE_DB_Master_Data.__RefLinkOutboundExists(const from_uid: TFRE_DB_GUID; const fieldname: TFRE_DB_NameType; to_object: TFRE_DB_GUID; const scheme_link: TFRE_DB_NameTypeRL): boolean;
var refoutkey : RFRE_DB_GUID_RefLink_InOut_Key;
    value     : PtrUInt;
begin
  __SetupOutboundLinkKey(from_uid,to_object,scheme_link,refoutkey);
  result := FMasterRefLinks.ExistsBinaryKey(@refoutkey,refoutkey.KeyLength,value);
  if result and
     (value<>$BAD0BEEF) then
       raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'internal outbound reflink structure bad, value invalid [%d]',[value]);
end;

function TFRE_DB_Master_Data.__RefLinkInboundExists(const from_uid: TFRE_DB_GUID; const fieldname: TFRE_DB_NameType; to_object: TFRE_DB_GUID; const scheme_link: TFRE_DB_NameTypeRL): boolean;
var refinkey : RFRE_DB_GUID_RefLink_InOut_Key;
    value    : PtrUInt;
begin
  __SetupInboundLinkKey(from_uid,to_object,scheme_link,refinkey);
  result := FMasterRefLinks.ExistsBinaryKey(@refinkey,refinkey.KeyLength,value);
  if result
     and (value<>$BEEF0BAD) then
       raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'internal inbound reflink structure bad, value invalid [%d]',[value]);
end;

procedure TFRE_DB_Master_Data.__CheckReferenceLink(const obj: TFRE_DB_Object; fieldname: TFRE_DB_NameType; link: TFRE_DB_GUID; var scheme_link: TFRE_DB_NameTypeRL);
var j       : NativeInt;
    ref_obj : TFRE_DB_Object;

begin
  //writeln('TODO _ PARALLEL CHECK OF REFLINK INDEX TREE');
  if not FetchObject(link,ref_obj,true) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'referential link check: link from obj(%s:%s) to obj(%s) : the to object does not exist!',[obj.UID_String,fieldname,GFRE_BT.GUID_2_HexString(link)]);
  if obj.IsVolatile or obj.IsSystem then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'referential link check: link from obj(%s:%s) to obj(%s) : the linking object is volatile or system!',[obj.UID_String,fieldname,GFRE_BT.GUID_2_HexString(link)]);
  scheme_link := uppercase(fieldname+'>'+ref_obj.SchemeClass);
   if __RefLinkOutboundExists(obj.UID,fieldname,link,scheme_link) then
     raise EFRE_DB_PL_Exception.Create(edb_ERROR,'outbound reflink already existing from  from obj(%s:%s) to obj(%s:%s)',[obj.UID_String,fieldname,GFRE_BT.GUID_2_HexString(link),ref_obj.SchemeClass]);
   if __RefLinkInboundExists(obj.UID,fieldname,link,uppercase(obj.SchemeClass+'<'+fieldname)) then
     raise EFRE_DB_PL_Exception.Create(edb_ERROR,'outbound reflink already existing from  from obj(%s:%s) to obj(%s:%s)',[obj.UID_String,fieldname,GFRE_BT.GUID_2_HexString(link),ref_obj.SchemeClass]);
end;

// Setup the "to_list" for KEY-UID,Field,(Subkeys)
// For every in the "to_list" referenced object set an inbound link, from KEY-UID

procedure TFRE_DB_Master_Data.__SetupInitialRefLink(const from_key: TFRE_DB_Object; const FromFieldToSchemename, LinkFromSchemenameField: TFRE_DB_NameTypeRL; const references_to: TFRE_DB_GUID);
var refoutkey : RFRE_DB_GUID_RefLink_InOut_Key;
    refinkey  : RFRE_DB_GUID_RefLink_InOut_Key;

begin
  __SetupOutboundLinkKey(from_key.UID,references_to,FromFieldToSchemename,refoutkey);
  if not FMasterRefLinks.InsertBinaryKey(@refoutkey,refoutkey.KeyLength,$BAD0BEEF) then
    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'although prechecked the reflink fromkey exists. :-(');

  __SetupInboundLinkKey(from_key.UID,references_to,LinkFromSchemenameField,refinkey);
  if not FMasterRefLinks.InsertBinaryKey(@refinkey,refinkey.KeyLength,$BEEF0BAD) then
    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'although prechecked the reflink tokey exists. :-(');
end;

procedure TFRE_DB_Master_Data._ChangeRefLink(const from_obj: TFRE_DB_Object; const fieldname: TFRE_DB_NameType; const references_to_list: TFRE_DB_GUIDArray);
//var refkey    : RFRE_DB_GUID_RefLink_Out_Key;
//    refinkey  : RFRE_DB_GUID_RefLink_In_Key;
//    reenc     : TREF_LinkEncapsulation;
//    i         : NativeInt;
//    dummy     : NativeUint;
//    refin_fn  : TFRE_DB_NameTypeRL;

    //j,k       : NativeInt;
    //dumlist   : TFRE_DB_ObjectReferences;
    //duminlist : TFRE_DB_ObjectReferences;
    //dummyold  : TFRE_DB_GUIDArray;

begin
  abort;
  //move(from_obj.UID,refkey.GUID,16);
  //move(fieldname[1],refkey.FieldName,Length(fieldname));
  //refkey.RefTyp := $99;
  //if not FMasterRefLinks.ExistsBinaryKey(@refkey,17+Length(fieldname),dummy) then
  //  raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'although prechecked the reflink key to change does not exists. :-(');
  //reenc := FREDB_PtrUIntToObject(dummy) as TREF_LinkEncapsulation;
  //
  ////dummyold := reenc.Links;
  //
  ////writeln(FREDB_GuidArray2String (reenc.Links));
  //// RemoveOldLinks
  //refin_fn        := from_obj.SchemeClass+'|'+fieldname;
  //refinkey.RefTyp := $AA;
  //move(from_obj.UID,refinkey.FromGuid,16);
  //move(refin_fn[1],refinkey.FromFieldScheme,length(refin_fn));
  //for i := 0 to high(reenc.FLinks) do begin
  //  move(reenc.FLinks[i],refinkey.GUID,16);
  //  if not FMasterRefLinks.RemoveBinaryKey(@refinkey,33+Length(refin_fn),dummy) then
  //    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'although prechecked the to delete reflink key does not exists. :-(');
  //end;
  //// RemoveOldLinks
  //
  //reenc.FLinks := Copy(references_to_list); // new links
  ////Update Inbound links
  //for i := 0 to high(references_to_list) do begin
  //  move(references_to_list[i],refinkey.GUID,16);
  //  if not FMasterRefLinks.InsertBinaryKey(@refinkey,33+Length(refin_fn),$BEEF0BAD) then
  //    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'although prechecked the inbound reflink key exists. :-(');
  //end;


  //Update Inbound links

  //writeln('------------------------');
  //writeln('UPDATED_REF_LINK');
  //writeln('------------------------');
  //dumlist := GetOutBoundRefLinks(from_obj.UID);
  //for i:=0 to high(dumlist) do
  //  begin
  //    writeln(GFRE_BT.GUID_2_HexString(from_obj.UID),' ',dumlist[i].fieldname,' -> ',FREDB_GuidArray2String(dumlist[i].linklist));
  //    for j:=0 to high(dumlist[i].linklist) do
  //      begin;
  //        duminlist := GetInboundLinks(dumlist[i].linklist[j]);
  //        for k := 0 to high(duminlist) do
  //          writeln('  Pointed to obj ',GFRE_BT.GUID_2_HexString(dumlist[i].linklist[j]),' <- by ',duminlist[k].fieldname,' ',FREDB_GuidArray2String(duminlist[k].linklist));
  //      end;
  //  end;
  //writeln('------------------------OLD_______');
  //for j:=0 to high(dummyold) do
  //  begin;
  //    duminlist := GetInboundLinks(dummyold[j]);
  //    for k := 0 to high(duminlist) do
  //      writeln('  Pointed to obj ',GFRE_BT.GUID_2_HexString(dummyold[j]),' <- by ',duminlist[k].fieldname,' ',FREDB_GuidArray2String(duminlist[k].linklist));
  //  end;
  //writeln('------------------------');
end;

procedure TFRE_DB_Master_Data._SetupInitialRefLinks(const from_key: TFRE_DB_Object; const references_to_list: TFRE_DB_ObjectReferences; const schemelink_arr: TFRE_DB_NameTypeRLArray);
var
  i: NativeInt;
begin
  assert(Length(references_to_list)=Length(schemelink_arr),'internal error');
  for i:=0 to high(references_to_list) do
    __SetupInitialRefLink(from_key,schemelink_arr[i],uppercase(from_key.SchemeClass+'<'+references_to_list[i].fieldname),references_to_list[i].linked_uid);
end;

procedure TFRE_DB_Master_Data._CheckRefIntegrityForObject(const obj: TFRE_DB_Object; var ref_array: TFRE_DB_ObjectReferences; var schemelink_arr: TFRE_DB_NameTypeRLArray);
var  i : NativeInt;
begin
  ref_array := obj.ReferencesFromData;
  SetLength(schemelink_arr,Length(ref_array));
  for i:=0 to high(ref_array) do
    __CheckReferenceLink(obj,ref_array[i].fieldname,ref_array[i].linked_uid,schemelink_arr[i]);
end;

function TFRE_DB_Master_Data._RemoveRefLinkFieldDelRefs(const obj: TFRE_DB_Object; field: TFRE_DB_FIELD; const check_only: boolean): TFRE_DB_Errortype;
begin
  writeln('_RemoveRefLinFieldefs FULL STOP');
  halt;
  result := edb_OK;
end;

function TFRE_DB_Master_Data.FetchNewTransactionID(const transid: string): String;
begin
  inc(F_DB_TX_Number);
  result := IntToStr(F_DB_TX_Number)+'#'+transid;
end;

function TFRE_DB_Master_Data.InternalStoreObjectFromStable(const obj: TFRE_DB_Object): TFRE_DB_Errortype;
var
   key    : TGuid;
   dummy  : PtrUInt;

   procedure Store(const obj:TFRE_DB_Object; var halt:boolean);
   begin
     dummy := FREDB_ObjectToPtrUInt(obj);
     key   := obj.UID;
     //writeln('RELOAD STORE : ',obj.UID_String,' ',obj.IsObjectRoot);
     if not FMasterPersistantObjStore.InsertBinaryKeyOrFetch(@key,sizeof(tguid),dummy) then
       result := edb_EXISTS;
     if result<>edb_OK then
       halt := true
   end;

begin
  Result := edb_OK;
  obj.ForAllObjectsBreakHierarchic(@Store);
end;

function TFRE_DB_Master_Data.InternalRebuildRefindex: TFRE_DB_Errortype;

  procedure BuildRef(const obj:TFRE_DB_Object);
  var references_to_list : TFRE_DB_ObjectReferences;
     scheme_links        : TFRE_DB_NameTypeRLArray;
  begin
    _CheckRefIntegrityForObject(obj,references_to_list,scheme_links); // Todo Check inbound From Links (unique?)
    if Length(references_to_list)>0 then
      begin
        //writeln('SETUP REFLINKS ',obj.UID_String,' ',Length(references_to_list));
        _SetupInitialRefLinks(obj,references_to_list,scheme_links);
      end;
  end;

begin
  ForAllObjectsInternal(true,false,@BuildRef);
  result := edb_OK;
end;

procedure TFRE_DB_Master_Data.InternalStoreLock;

  procedure StoreLock(const obj:TFRE_DB_Object);
  begin
    if obj.IsObjectRoot then
      obj.Set_Store_Locked(true);
  end;

begin
  ForAllObjectsInternal(true,false,@Storelock);
end;

procedure TFRE_DB_Master_Data.DEBUG_CleanUpMasterData;

  procedure CleanReflinks(var refl : NativeUint);
  begin
    if (refl<>$BEEF0BAD) and
       (refl<>$BAD0BEEF) then
         raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'tree node inconsistency/bad value');
  end;

  procedure CleanObj(var ob : NativeUint);
  var obj : TFRE_DB_Object;
  begin
    if ob=0 then
      exit;
    obj := TFRE_DB_Object(FREDB_PtrUIntToObject(ob));
    if obj.IsObjectRoot then
      begin
        obj.Set_Store_Locked(False);
        obj.Free;
      end;
  end;

  procedure CleanAllChilds(var ob : NativeUint);
  var obj : TFRE_DB_Object;
  begin
    obj := TFRE_DB_Object(FREDB_PtrUIntToObject(ob));
    if not obj.IsObjectRoot then
     ob:=0;
  end;


begin
  FMasterPersistantObjStore.LinearScan(@CleanAllChilds);
  FMasterPersistantObjStore.LinearScan(@CleanObj);
  FMasterPersistantObjStore.Clear;
  FMasterVolatileObjStore.LinearScan(@CleanAllChilds);
  FMasterVolatileObjStore.LinearScan(@CleanObj);
  FMasterVolatileObjStore.Clear;
  FMasterRefLinks.LinearScan(@CleanReflinks);
  FMasterRefLinks.Clear;
  FMasterCollectionStore.Clear;
  F_DB_TX_Number            := 0;
end;

//procedure TFRE_DB_Master_Data._AddRefLink(const from_obj, to_obj: TGuid; const rebuild: boolean);
//var
//    from_key,to_key   : TGUID_RefLink_Key;
//    //from_o,to_o       : TFRE_DB_Object;
//    from_field        : TFRE_DB_FIELD;
//    to_field          : TFRE_DB_FIELD;
//    max,current       : integer;
//    guidarray         : TFRE_DB_GUIDArray;
//
//    //procedure _SetupInitial(const set_guid:TGuid);
//    //begin
//    //  SetLength(guidarray,c_REFLINK_BLOCK_SIZE);
//    //  guidarray[0] := set_guid;
//    //end;
//
//    procedure _SetupNext(const set_guid:TGuid);
//    var null_fnd,i : integer;
//        len        : integer;
//    begin
//      for i:= 0 to high(guidarray) do begin
//        if FREDB_Guids_Same(guidarray[i],set_guid) then begin
//          if not rebuild then begin
//            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'guid %s already set in linklist',[GFRE_BT.GUID_2_HexString(set_guid)]);
//          end else begin
//            GFRE_DB.LogWarning(dblc_REFERENCES,'rebuild : guid %s already set in linklist',[GFRE_BT.GUID_2_HexString(set_guid)]);
//          end;
//        end;
//      end;
//      null_fnd:=-1;
//      for i:= 0 to high(guidarray) do begin
//        if FREDB_Guids_Same(guidarray[i],CFRE_DB_NullGUID) then begin
//          null_fnd:=i;
//          break;
//        end;
//      end;
//      if null_fnd=-1 then begin
//        len := length(guidarray);
//        SetLength(guidarray,length(guidarray)+c_REFLINK_BLOCK_SIZE);
//        guidarray[len]      := set_guid;
//      end else begin
//        guidarray[null_fnd] := set_guid;
//      end;
//    end;
//
//begin
//  //if not Exists(from_obj) then raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'while updating reflinks, the  from object uid=%s was not found',[GFRE_BT.GUID_2_HexString(from_obj)]);
//  //if not Exists(to_obj) then raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'while updating reflinks, the to object uid=%s was not found',[GFRE_BT.GUID_2_HexString(to_obj)]);
//  //from_field_name := GFRE_BT.GUID_2_HexString(from_obj);
//  //to_field_name   := GFRE_BT.GUID_2_HexString(to_obj);
//  assert(from_obj<>to_obj);
//  from_key.Part1 := TGUID_Access(from_obj).Part1;
//  from_key.Part2 := TGUID_Access(from_obj).Part2;
//  from_key.Rtyp  := $aa;
//
//  to_key.Part1 := TGUID_Access(to_obj).Part1;
//  to_key.Part2 := TGUID_Access(to_obj).Part2;
//  to_key.Rtyp  := $bb;
//
//  FMasterRefLinks.InsertBinaryKey(@from_key.Part1,sizeof(from_key),dummy);
//
//  from_field := FReferentialLinks._Field('F').AsObject._Field(from_field_name);
//  to_field   := FReferentialLinks._Field('T').AsObject._Field(to_field_name);
//  guidarray := from_field.AsGUIDArr;
//  _SetupNext(to_obj);
//  from_field.AsGUIDArr:=guidarray;
//  guidarray := to_field.AsGUIDArr;
//  _SetupNext(from_obj);
//  to_field.AsGUIDArr:=guidarray;
//end;
//

constructor TFRE_DB_Master_Data.Create(const master_name: string ; const Layer : IFRE_DB_PERSISTANCE_LAYER);
begin
  FMasterPersistantObjStore := TFRE_ART_TREE.Create;
  FMasterVolatileObjStore   := TFRE_ART_TREE.Create;
  FMasterRefLinks           := TFRE_ART_TREE.Create;
  FMasterCollectionStore    := TFRE_DB_CollectionManageTree.Create;
  F_DB_TX_Number            := 0;
  FLayer                    := Layer;
end;

destructor TFRE_DB_Master_Data.Destroy;
begin
  DEBUG_CleanUpMasterData;
  FMasterPersistantObjStore.Free;
  FMasterVolatileObjStore.Free;
  FMasterRefLinks.Free;
  FMasterCollectionStore.Free;
  inherited Destroy;
end;

function TFRE_DB_Master_Data.GetReferences(const obj_uid: TGuid; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType): TFRE_DB_GUIDArray;
var obr   : TFRE_DB_ObjectReferences;
    i,cnt : NativeInt;
    add   : boolean;
    spf   : TFRE_DB_NameType;
    fef   : TFRE_DB_NameType;
begin
  if from then
    obr := GetOutBoundRefLinks(obj_uid)
  else
    obr := GetInboundLinks(obj_uid);
  SetLength(result,length(obr));

  spf := uppercase(scheme_prefix_filter);
  fef := uppercase(field_exact_filter);

  cnt := 0;
  for i:=0 to high(obr) do
    if ((spf='') or  (pos(spf,obr[i].schemename)=1)) and ((fef='') or (fef=obr[i].fieldname)) then
      begin
        result[cnt] := obr[i].linked_uid;
        inc(cnt);
      end;
  SetLength(result,cnt);
end;

function TFRE_DB_Master_Data.GetReferencesCount(const obj_uid: TGuid; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType): NativeInt;
var obr   : TFRE_DB_ObjectReferences;
    i     : NativeInt;
    add   : boolean;
    spf   : TFRE_DB_NameType;
    fef   : TFRE_DB_NameType;
begin
  if from then
    obr := GetOutBoundRefLinks(obj_uid)
  else
    obr := GetInboundLinks(obj_uid);

  spf := uppercase(scheme_prefix_filter);
  fef := uppercase(field_exact_filter);

  result := 0;
  for i:=0 to high(obr) do
    if ((spf='') or  (pos(spf,obr[i].schemename)=1)) and ((fef='') or (fef=obr[i].fieldname)) then
      inc(result);
end;

function TFRE_DB_Master_Data.GetReferencesDetailed(const obj_uid: TGuid; const from: boolean; const scheme_prefix_filter: TFRE_DB_NameType; const field_exact_filter: TFRE_DB_NameType): TFRE_DB_ObjectReferences;
var obr   : TFRE_DB_ObjectReferences;
    i,cnt : NativeInt;
    add   : boolean;
    spf   : TFRE_DB_NameType;
    fef   : TFRE_DB_NameType;
begin
  if from then
    obr := GetOutBoundRefLinks(obj_uid)
  else
    obr := GetInboundLinks(obj_uid);
  SetLength(result,length(obr));

  spf := uppercase(scheme_prefix_filter);
  fef := uppercase(field_exact_filter);

  cnt := 0;
  for i:=0 to high(obr) do
    if ((spf='') or  (pos(spf,obr[i].schemename)=1)) and ((fef='') or (fef=obr[i].fieldname)) then
      begin
        result[cnt] := obr[i];
        inc(cnt);
      end;
  SetLength(result,cnt);
end;

function TFRE_DB_Master_Data.ExistsObject(const obj_uid: TGuid): Boolean;
var dummy : NativeUint;
begin
  if FMasterVolatileObjStore.ExistsBinaryKey(@obj_uid,SizeOf(TGuid),dummy) then
    exit(true);
  if FMasterPersistantObjStore.ExistsBinaryKey(@obj_uid,SizeOf(TGuid),dummy) then
    exit(true);
  exit(false);
end;

function TFRE_DB_Master_Data.FetchObject(const obj_uid: TGuid; var obj: TFRE_DB_Object ; const internal_obj : boolean): boolean;
var dummy : NativeUint;
    clobj : TFRE_DB_Object;
begin
  obj := nil;
  //write('TRY MASTER FETCH ',gfre_bt.GUID_2_HexString(obj_uid));
  result := FMasterVolatileObjStore.ExistsBinaryKey(@obj_uid,SizeOf(TGuid),dummy);
  if result then
    begin
      obj := FREDB_PtrUIntToObject(dummy) as TFRE_DB_Object;
      obj.Assert_CheckStoreLocked;
    end
  else
    begin
     result := FMasterPersistantObjStore.ExistsBinaryKey(@obj_uid,SizeOf(TGuid),dummy);
     if result then
       begin
         obj := FREDB_PtrUIntToObject(dummy) as TFRE_DB_Object;
         //if Length(obj.__InternalGetCollectionList)<1 then
         //  begin
         //    writeln('OBJ FCUKED UP');
         //    writeln(obj.DumpToString());
         //    halt;
         //    abort;
         //  end;
         //writeln(' IS OK ! ',obj.InternalUniqueDebugKey);
       end
     else
       //writeln(' FAILED !!!!!!');
    end;
  if result and
     not internal_obj then
       begin
         obj.Assert_CheckStoreLocked;
         obj.Set_Store_Locked(false);
         try
          if Length(obj.__InternalGetCollectionList)<1 then
            abort;
          clobj := obj.CloneToNewObject;
         finally
           obj.Set_Store_Locked(true);
         end;
         obj := clobj;
       end;
end;

procedure TFRE_DB_Master_Data.StoreObject(const obj: TFRE_DB_Object; const check_only: boolean);
var references_to_list : TFRE_DB_ObjectReferences;
    key                : TGuid;
    dummy              : PtrUInt;
    scheme_links       : TFRE_DB_NameTypeRLArray;
begin
  key := obj.UID;
  _CheckRefIntegrityForObject(obj,references_to_list,scheme_links); // Todo Check inbound From Links (unique?)
  if (obj.IsVolatile
     or obj.IsSystem)
     and (Length(references_to_list)>0) then
       raise EFRE_DB_PL_Exception.Create(edb_INVALID_PARAMS,'a volatile or system object is not allowed to reference other objects');
  if obj.IsVolatile then
    begin
      if check_only then
        begin
          if FMasterVolatileObjStore.ExistsBinaryKey(@key,SizeOf(TGuid),dummy) then // TODO:Remove DEBUG CHECK
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'cannot store volatile object')
        end
      else
        begin
          if not FMasterVolatileObjStore.InsertBinaryKey(@key,SizeOf(TGuid),FREDB_ObjectToPtrUInt(obj)) then
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'cannot store volatile object')
        end;
    end
  else
    begin // Not Volatile
      dummy := FREDB_ObjectToPtrUInt(obj);
      if check_only then
        begin
          if FMasterPersistantObjStore.ExistsBinaryKey(@key,SizeOf(TGuid),dummy) then
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'cannot store persistent object');
        end
      else
        begin
          if not FMasterPersistantObjStore.InsertBinaryKeyOrFetch(@key,sizeof(tguid),dummy) then
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'cannot store persistent object [%s]',[obj.InternalUniqueDebugKey]);
          if Length(references_to_list)>0 then
            _SetupInitialRefLinks(obj,references_to_list,scheme_links);
        end;
    end;
end;

procedure TFRE_DB_Master_Data.DeleteObject(const obj_uid: TGuid; const check_only: boolean);
var dummy : PtrUInt;
begin
  if check_only then
    begin
      if GetReferencesCount(obj_uid,false) > 0 then
        raise EFRE_DB_PL_Exception.Create(edb_OBJECT_REFERENCED,'DELETE OF OBJECT [%s] FAILED, OBJECT IS REFERENCED',[GFRE_BT.GUID_2_HexString(obj_uid)]);
      exit;
    end;
  if not FMasterVolatileObjStore.RemoveBinaryKey(@obj_uid,SizeOf(TGuid),dummy) then
    if not FMasterPersistantObjStore.RemoveBinaryKey(@obj_uid,SizeOf(TGuid),dummy) then
      raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'DELETE OF OBJECT [%s] FAILED, OBJECT NOT FOUND',[GFRE_BT.GUID_2_HexString(obj_uid)])
end;

procedure TFRE_DB_Master_Data.ForAllObjectsInternal(const pers, volatile: boolean; const iter: TFRE_DB_Obj_Iterator);

  procedure ObjCallBack(var val:NativeUint);
  begin
    iter(FREDB_PtrUIntToObject(val) as TFRE_DB_Object);
  end;

begin
  if pers then
    FMasterPersistantObjStore.LinearScan(@ObjCallback);
  if volatile then
    FMasterPersistantObjStore.LinearScan(@ObjCallback);
end;

function TFRE_DB_Master_Data.MasterColls: TFRE_DB_CollectionManageTree;
begin
  result := FMasterCollectionStore;
end;

procedure TFRE_DB_Master_Data.ApplyWAL(const WALStream: TStream);
var WAL_Transaction : TFRE_DB_TransactionalUpdateList;
begin
  writeln('WAL REAPPLY/REPAIR ',FMastername);
  while WALStream.Position<>WALStream.Size do
    begin
      WAL_Transaction := TFRE_DB_TransactionalUpdateList.Create('',self);
      try
        WAL_Transaction.ReadFromBackWalStream(WALStream);
        WAL_Transaction.Commit(FLayer,true);
      finally
        WAL_Transaction.Free;
        WAL_Transaction:=nil;
      end;
      writeln('--- READ BACK ...  ',WALStream.Position,'   ',WALStream.Size);
    end;
  writeln('FIN: --- READ BACK ...  ',WALStream.Position,'   ',WALStream.Size);
end;

{ TFRE_DB_TextIndex }

procedure TFRE_DB_TextIndex.SetBinaryComparableKey(const keyvalue: TFRE_DB_String; const key_target: PByte; var key_len: NativeInt; const is_null: boolean);
var str : TFRE_DB_String;
begin
  if FCaseInsensitive then
    str := UpperCase(keyvalue)
  else
    str := keyvalue;
  str := #1+str;
  if is_null then
    str := #0#0
  else
    if str=#1 then
      str := #0#1;
  key_len := Length(str);
  Move(str[1],key_target^,key_len);
end;

procedure TFRE_DB_TextIndex.StreamHeader(const stream: TStream);
begin
  inherited StreamHeader(stream);
  if FCaseInsensitive then
    stream.WriteByte(1)
  else
    stream.WriteByte(0);
end;

procedure TFRE_DB_TextIndex.InitializeNullKey;
begin
  SetBinaryComparableKey('',@nullkey,nullkeylen,true);
end;


constructor TFRE_DB_TextIndex.Create(const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique, case_insensitive: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean; const unique_null: boolean);
begin
  inherited Create(idx_name,fieldname,fieldtype,unique,collection,allow_null,unique_null);
  FCaseInsensitive := case_insensitive;
end;

constructor TFRE_DB_TextIndex.CreateStreamed(const stream: TStream; const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean; const unique_null: boolean);
var ci : Boolean;
begin
  ci := stream.ReadByte=1;
  Create(idx_name,fieldname,fieldtype,unique,ci,collection,allow_null,unique_null);
  LoadIndex(stream,collection);
end;


procedure TFRE_DB_TextIndex.FieldTypeIndexCompatCheck(fld: TFRE_DB_FIELD);
begin
  if fld.FieldType<>fdbft_String then
    raise EFRE_DB_PL_Exception.Create(edb_ILLEGALCONVERSION,'the text index can only be used to index a string field, not a [%s] field. Maybe use a calculated field with results a string field',[fld.FieldTypeAsString])
end;

procedure TFRE_DB_TextIndex.TransformToBinaryComparable(fld: TFRE_DB_FIELD; const key: PByte; var keylen: Nativeint);
var val           : TFRE_DB_String;
    is_null_value : Boolean;
begin
  is_null_value := not assigned(fld);
  if not is_null_value then
    val := fld.AsString
  else
    val := '';
  SetBinaryComparableKey(val,key,keylen,is_null_value)
end;

function TFRE_DB_TextIndex.SupportsDataType(const typ: TFRE_DB_FIELDTYPE): boolean;
begin
  if typ=fdbft_String then
    exit(true)
  else
    exit(false)
end;

function TFRE_DB_TextIndex.IndexTypeTxt: String;
begin
  result := 'text';
end;

function TFRE_DB_TextIndex.ForAllIndexedTextRange(const min, max: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean): boolean;
var lokey,hikey       : Array [0..8] of Byte;
    lokeylen,hikeylen : NativeInt;
    lokeyp,hikeyp     : PByte;

   procedure IteratorBreak(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var break : boolean);
   begin
     (FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore).AppendObjectUIDS(guids,ascending); //ForAllBreak(func,ascending,break);
   end;

begin
  if only_count_unique_vals=false then
    E_FOS_Implement;
  if not min_is_null then
    begin
      SetBinaryComparableKey(min,@lokey,lokeylen,min_is_null);
      lokeyp := lokey;
    end
  else
    lokeyp := nil;
  if not max_is_max then
    begin
      SetBinaryComparableKey(max,@hikey,hikeylen,max_is_max);
      hikeyp := hikey;
    end
  else
    hikeyp := nil;
  result := FIndex.RangeScan(lokeyp,hikeyp,lokeylen,hikeylen,@IteratorBreak,max_count,skipfirst,ascending)
end;

function TFRE_DB_TextIndex.ForAllIndexPrefixString(const prefix: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean): boolean;
var
    transkey : Array [0..CFREA_maxKeyLen] of Byte;
    keylen   : NativeInt;

   procedure IteratorBreak(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint ; var break : boolean);
   begin
     (FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore).AppendObjectUIDS(guids,ascending); //ForAllBreak(iterator,ascending,break);
   end;

begin
  if only_count_unique_vals=false then
    E_FOS_Implement;
  SetBinaryComparableKey(prefix,@transkey,keylen,false);
  result := FIndex.PrefixScan(@transkey,keylen,@IteratorBreak);
end;


{ TFRE_DB_MM_Index }

constructor TFRE_DB_MM_Index.Create(const idx_name, fieldname: TFRE_DB_NameType; const fieldtype: TFRE_DB_FIELDTYPE; const unique: boolean; const collection: IFRE_DB_PERSISTANCE_COLLECTION; const allow_null: boolean; const unique_null: boolean);
begin
  FIndex           := TFRE_ART_TREE.Create;
  FIndexName       := idx_name;
  FUniqueName      := UpperCase(FIndexName);
  FUnique          := unique;
  FFieldname       := fieldname;
  FUniqueFieldname := uppercase(fieldname);
  FFieldType       := fieldtype;
  FUnique          := unique;
  FCollection      := collection;
  FAllowNull       := allow_null;
  FUniqueNullVals  := unique_null;
  case fieldtype of
    fdbft_GUID,
    fdbft_ObjLink:      FFixedKeylen := 16;
    fdbft_Byte:         FFixedKeylen := 1;
    fdbft_Int16:        FFixedKeylen := 2;
    fdbft_UInt16:       FFixedKeylen := 2;
    fdbft_Int32:        FFixedKeylen := 4;
    fdbft_UInt32:       FFixedKeylen := 4;
    fdbft_Int64:        FFixedKeylen := 8;
    fdbft_UInt64:       FFixedKeylen := 8;
    //fdbft_Real32:       FFixedKeylen := 4;
    //fdbft_Real64:       FFixedKeylen := 8;
    fdbft_Currency:     FFixedKeylen := 8;
    fdbft_String:       FFixedKeylen := 8;
    fdbft_Boolean:      FFixedKeylen := 1;
    fdbft_DateTimeUTC:  FFixedKeylen := 8;
    else
      raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unssoported fieldtype for index '+CFRE_DB_FIELDTYPE[fieldtype]);
  end;
  InitializeNullKey;
end;

destructor TFRE_DB_MM_Index.Destroy;

  procedure ClearIndex(var dummy : NativeUint);
  begin
    TFRE_DB_IndexValueStore(FREDB_PtrUIntToObject(dummy)).free;
  end;

begin
  FIndex.LinearScan(@ClearIndex);
  FIndex.Free;
end;

function TFRE_DB_MM_Index.Indexname: TFRE_DB_NameType;
begin
  result := FIndexName;
end;

function TFRE_DB_MM_Index.Uniquename: PFRE_DB_NameType;
begin
  result := @FUniqueName;
end;

function TFRE_DB_MM_Index.NullvalueExists(var vals: TFRE_DB_IndexValueStore): boolean;
var dummy  : NativeUint;
begin
  result := FIndex.ExistsBinaryKey(@nullkey,nullkeylen,dummy);
  if result then
    vals := FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore
  else
    vals := nil;
end;

function TFRE_DB_MM_Index.NullvalueExistsForObject(const obj: TFRE_DB_Object): boolean;
var values : TFRE_DB_IndexValueStore;
begin
  if NullvalueExists(values) then
    result := values.Exists(obj.UID)
  else
    result :=false;
end;

procedure TFRE_DB_MM_Index.IndexAddCheck(const obj: TFRE_DB_Object; const check_only: boolean);
var
    fld       : TFRE_DB_FIELD;
    isNullVal : boolean;
    key       : Array [0..CFREA_maxKeyLen] of Byte;
    keylen    : NativeInt;

begin
  isNullVal := not obj.FieldOnlyExisting(FFieldname,fld);
  if isNullVal
    and (not FAllowNull) then
      raise EFRE_DB_PL_Exception.Create(edb_UNSUPPORTED,'for the index [%s] the usage of null values (=unset fields) is not allowed',[_GetIndexStringSpec]);
  if not isNullVal then
    FieldTypeIndexCompatCheck(fld);
  TransformtoBinaryComparable(fld,@key,keylen);
  if check_only then
    _InternalCheckAdd(@key,keylen,isNullVal,false,obj.uid)
  else
    _InternalAddGuidToValstore(@key,keylen,isNullVal,obj.UID);
end;

procedure TFRE_DB_MM_Index.IndexUpdCheck(const new_obj, old_obj: TFRE_DB_Object; const check_only: boolean);
var
    oldfld,newfld  : TFRE_DB_FIELD;
    obj_uid        : TGUID;
    dummy          : NativeUint;
    values         : TFRE_DB_IndexValueStore;
    isNullValue    : boolean;
    OldIsNullValue : boolean;
    key            : Array [0..CFREA_maxKeyLen] of Byte;
    keylen         : NativeInt;
    ukey           : Array [0..CFREA_maxKeyLen] of Byte;
    ukeylen        : NativeInt;

begin
  assert(assigned(new_obj));
  assert(assigned(old_obj));
  assert(new_obj.UID=old_obj.UID);
  obj_uid := new_obj.UID;
  OldIsNullValue := not old_obj.FieldOnlyExisting(FFieldname,oldfld);
  TransformtoBinaryComparable(oldfld,key,keylen);
  isNullValue    := not new_obj.FieldOnlyExisting(FFieldname,newfld);
  if not isNullValue then
    FieldTypeIndexCompatCheck(newfld);
  TransformtoBinaryComparable(newfld,ukey,ukeylen);
  if CompareTransformedKeys(key,ukey,keylen,ukeylen) then // This should not happen, as the change compare has to happen earlier
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'cant update the index for object [%s] / for the unique index [%s] the values would be the same ([%s]->[%s])',[new_obj.UID_String,_GetIndexStringSpec,FFieldname,GetStringRepresentationOfTransientKey(OldIsNullValue,key,keylen),GetStringRepresentationOfTransientKey(isNullValue,ukey,ukeylen)]);
  //writeln('INDEX CHANGE ',_GetIndexStringSpec,' REMOVE VAL ',oldfld.AsString,' ',new_obj.UID_String);
  //writeln('INDEX CHANGE ',_GetIndexStringSpec,' ADD VAL '   ,newfld.AsString,' ',new_obj.UID_String);
  if check_only then
    begin
      _InternalCheckAdd(@ukey,ukeylen,isNullValue,true,obj_uid)
    end
  else
    begin
      // Update - (1) Remove old object index value from index
      //          (2) Add new object/field value to index
      _InternalRemoveGuidFromValstore(@key,keylen,isNullValue,obj_uid);
      _InternalAddGuidToValstore(@ukey,ukeylen,isNullValue,obj_uid);
    end;
end;

procedure TFRE_DB_MM_Index.IndexDelCheck(const obj, new_obj: TFRE_DB_Object; const check_only: boolean);
var oldfld         : TFRE_DB_FIELD;
    obj_uid        : TGuid;
    OldIsNullValue : boolean;
    key            : Array [0..CFREA_maxKeyLen] of Byte;
    keylen         : NativeInt;
    //ukey           : Array [0..CFREA_maxKeyLen] of Byte;
    //ukeylen        : NativeInt;

begin
  obj_uid := obj.UID;
  OldIsNullValue := not obj.FieldOnlyExisting(FFieldname,oldfld);
  TransformtoBinaryComparable(oldfld,@key,keylen);
  if check_only then
    _InternalCheckDel(@key,keylen,OldIsNullValue,obj_uid)
  else
    _InternalRemoveGuidFromValstore(@key,keylen,OldIsNullValue,obj_uid); // Remove old object index value from index
  if FAllowNull
    and assigned(new_obj) then  // if the new_obj is not assigned this is a full delete, not a field delete(!)
      IndexAddCheck(new_obj,check_only); // Need to Transform Null Value
end;

function TFRE_DB_MM_Index.IsUnique: Boolean;
begin
  result := FUnique;
end;


procedure TFRE_DB_MM_Index.AppendAllIndexedUids(var guids: TFRE_DB_GUIDArray; const ascending: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);

  procedure NodeProc(var value : NativeUint);
  begin
    (FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore).AppendObjectUIDS(guids,ascending);
  end;

begin
  if (max_count<>0) or
     (skipfirst<>0) then
       if ((only_count_unique_vals=false) and (not _IndexIsFullUniqe)) then
         E_FOS_Implement;
  if ascending then
    FIndex.LinearScan(@NodeProc)
  else
    FIndex.LinearScan(@NodeProc,true);
end;

function TFRE_DB_MM_Index.IndexedCount(const unique_values: boolean): NativeInt;

   procedure CountValuesIndex(var dummy : NativeUint);
   begin
     result := result + TFRE_DB_IndexValueStore(FREDB_PtrUIntToObject(dummy)).ObjectCount;
   end;

begin
  if unique_values then
    result := FIndex.GetValueCount
  else
    begin
      if (FUniqueNullVals=false)
         or (FUnique=false) then
           begin
             result := 0;
             FIndex.LinearScan(@CountValuesIndex); //TODO: Replace with Bookkeeping variant
           end
      else
        result := FIndex.GetValueCount;
    end;
end;

function TFRE_DB_MM_Index.IndexIsFullyUnique: Boolean;
begin
  result := _IndexIsFullUniqe;
end;

procedure TFRE_DB_MM_Index._InternalCheckAdd(const key: PByte; const keylen: Nativeint; const isNullVal, isUpdate: Boolean; const obj_uid: TGUID);
var dummy  : NativeUint;
    values : TFRE_DB_IndexValueStore;
begin
  if isNullVal and
     not FAllowNull then
       raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'trying to add a null value for the index [%s/%s/%s], which is not allowing null values value=[ %s]',[FCollection.CollectionName(false),FIndexName,FFieldname,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)]);
  if FIndex.ExistsBinaryKey(key,keylen,dummy) then // if not existing then
    begin
      values := FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore;
      if isNullVal then
        begin
          if FUniqueNullVals then
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'for the null-unique index [%s] the null key value already exists [ %s]',[_GetIndexStringSpec,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)])
          else
            begin
              if values.Exists(obj_uid) then
                raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'for the non null-unique index [%s] the value(=obj) already exists',[_GetIndexStringSpec])
            end;
        end
      else
        begin
          if FUnique then
            raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'for the unique index [%s] the key already exists [ %s]',[_GetIndexStringSpec,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)])
          else
            begin
              if values.Exists(obj_uid) then
                raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'for the non unique index [%s] the value [ %s] already exists',[_GetIndexStringSpec,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)])
            end;
        end
    end
end;

procedure TFRE_DB_MM_Index._InternalCheckDel(const key: PByte; const keylen: Nativeint; const isNullVal : boolean ; const obj_uid: TGUID);
var dummy        : NativeUint;
    values       : TFRE_DB_IndexValueStore;
    nullvalExist : Boolean;
begin
  if not FAllowNull
     and isNullVal then
       raise EFRE_DB_PL_Exception.Create(edb_ERROR,'delete check failed idx [%s] does not allow null values.',[_GetIndexStringSpec]);

  nullvalExist := NullvalueExists(values);
  if FUniqueNullVals
     and isNullVal
     and nullvalExist then
       raise EFRE_DB_PL_Exception.Create(edb_ERROR,'delete check failed idx [%s] does allow only one unique null value, and a null value already exist',[_GetIndexStringSpec]);

  if FIndex.ExistsBinaryKey(key,keylen,dummy) then // if not existing then
    begin
      values := FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore;
      if not values.Exists(obj_uid) then
        raise EFRE_DB_PL_Exception.Create(edb_ERROR,'delete check failed idx [%s] value does not exist [ %s]',[_GetIndexStringSpec,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)])
    end
  else
    raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'for the unique index [%s] the key to delete does not exists [ %s]',[_GetIndexStringSpec,GetStringRepresentationOfTransientKey(isNullVal,key,keylen)])
end;

procedure TFRE_DB_MM_Index._InternalAddGuidToValstore(const key: PByte; const keylen: Nativeint ; const isNullVal : boolean ; const uid: TGUID);
var
    dummy : NativeUint;
   values : TFRE_DB_IndexValueStore;
begin
  values   := TFRE_DB_IndexValueStore.Create;
  dummy    := FREDB_ObjectToPtrUInt(values);
  if FIndex.InsertBinaryKeyOrFetch(key,keylen,dummy) then
    begin //new
      if not FIndex.ExistsBinaryKey(key,keylen,dummy) then
        begin
          FIndex.InsertBinaryKey(key,keylen,dummy); // debug line
          GFRE_BT.CriticalAbort('inserted key but not finding it, failure in tree structure!');
        end;
      if not values.Add(uid) then
        raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unexpected internal index unique/empty/add failure');
    end
  else
    begin // exists
      values.free;
      values := FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore;
      if isNullVal then
        begin
          if FUniqueNullVals then
            raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unexpected internal null-unique index add/exists failure')
          else
            if not values.Add(UID) then
              raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unexpected internal index non null-unique add failure');
        end
      else
        begin
          if FUnique then
            raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unexpected internal unique index add/exists failure')
          else
            if not values.Add(UID) then
              raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'unexpected internal index non unique add failure');
        end;
    end;
end;

procedure TFRE_DB_MM_Index._InternalRemoveGuidFromValstore(const key: PByte; const keylen: Nativeint; const isNullVal: boolean; const uid: TGUID);
var
    dummy : NativeUint;
   values : TFRE_DB_IndexValueStore;
begin
  if not FIndex.ExistsBinaryKey(key,keylen,dummy) then
    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'index/field [%s] update, cannot find old value?',[_GetIndexStringSpec]);
  values := FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore;
  if not values.RemoveUID(uid) then
    raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'index/field [%s] update, cannot find old obj uid [%s] value in indexvaluestore?',[_GetIndexStringSpec,GFRE_BT.GUID_2_HexString(uid)]);
  if values.ObjectCount=0 then
    if not FIndex.RemoveBinaryKey(key,keylen,dummy) then
      raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'index/field [%s] update, cannot remove the index node entry for old obj uid [%s] in indextree?',[_GetIndexStringSpec,GFRE_BT.GUID_2_HexString(uid)]);
end;

function TFRE_DB_MM_Index.GetStringRepresentationOfTransientKey(const isnullvalue: boolean; const key: PByte; const keylen: Nativeint): String;
begin
  if isnullvalue then
    exit('(NULL)')
  else
    result := GFRE_BT.Dump_Binary(@key[0],keylen,true,false)
end;

function TFRE_DB_MM_Index.FetchIndexedValsTransformedKey(var obj: TFRE_DB_GUIDArray; const key: PByte; const keylen: Nativeint): boolean;
var dummy : NativeUint;
begin
  SetLength(obj,0);
  result := FIndex.ExistsBinaryKey(key,keylen,dummy);
  if result then
    (FREDB_PtrUIntToObject(dummy) as TFRE_DB_IndexValueStore).AppendObjectUIDS(obj,true)
  //else
  //  obj := nil;
end;

function TFRE_DB_MM_Index.CompareTransformedKeys(const key1, key2: PByte; const keylen1, keylen2: Nativeint): boolean;
begin
  if keylen1=keylen2 then
    if CompareMemRange(@key1[0],@key2[0],keylen1)=0 then
      exit(true);
  exit(false);
end;

procedure TFRE_DB_MM_Index.StreamHeader(const stream: TStream);
begin
  stream.WriteAnsiString(ClassName);
  stream.WriteAnsiString(FIndexName);
  stream.WriteAnsiString(FFieldname);
  stream.WriteAnsiString(CFRE_DB_FIELDTYPE_SHORT[FFieldType]);
  if FUnique then
    stream.WriteByte(1)
  else
    stream.WriteByte(0);
  if FAllowNull then
    stream.WriteByte(1)
  else
    stream.WriteByte(0);
  if FUniqueNullVals then
    stream.WriteByte(1)
  else
    stream.WriteByte(0);
end;

procedure TFRE_DB_MM_Index.StreamToThis(const stream: TStream);
begin
  StreamHeader(stream);
  StreamIndex(stream);
end;

procedure TFRE_DB_MM_Index.StreamIndex(const stream: TStream);
var i:NativeInt;

  procedure StreamKeyVal(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint);
  var ixs : TFRE_DB_IndexValueStore;
  begin
    stream.WriteQWord(KeyLen);
    stream.WriteBuffer(Key^,KeyLen);
    ixs := FREDB_PtrUIntToObject(value) as TFRE_DB_IndexValueStore;
    ixs.StreamToThis(stream);
  end;

begin
  i := FIndex.GetValueCount;
  stream.WriteQWord(i);
  FIndex.LinearScanKeyVals(@StreamKeyVal);
end;

procedure TFRE_DB_MM_Index.LoadIndex(const stream: TStream ; const coll: IFRE_DB_PERSISTANCE_COLLECTION);
var i,cnt      : NativeInt;
    keylen     : NativeUint;
    key        : RawByteString;
    ixs        : TFRE_DB_IndexValueStore;

begin
  cnt := stream.ReadQWord;
  for i := 1 to cnt do
    begin
      keylen := stream.ReadQWord;
      SetLength(key,keylen);
      stream.ReadBuffer(Key[1],keylen);
      ixs := TFRE_DB_IndexValueStore.Create;
      ixs.LoadFromThis(stream,coll);
      if not FIndex.InsertBinaryKey(@key[1],keylen,FREDB_ObjectToPtrUInt(ixs)) then
        raise EFRE_DB_PL_Exception.Create(edb_ERROR,'stream load : index add failure [%s]',[key]);
    end;
end;

class function TFRE_DB_MM_Index.CreateFromStream(const stream: TStream ; const coll : IFRE_DB_PERSISTANCE_COLLECTION): TFRE_DB_MM_Index;
var
    cn,idxn,fieldn : String;
    ft             : TFRE_DB_FIELDTYPE;
    unique         : boolean;
    allownull      : boolean;
    uniquenull     : boolean;

begin
  cn        := stream.ReadAnsiString;
  idxn      := stream.ReadAnsiString;
  fieldn    := stream.ReadAnsiString;
  ft        := FREDB_FieldtypeShortString2Fieldtype(stream.ReadAnsiString);
  unique    := stream.ReadByte=1;
  allownull := stream.ReadByte=1;
  uniquenull:= stream.ReadByte=1;
  case cn of
    'TFRE_DB_TextIndex'     : result := TFRE_DB_TextIndex.CreateStreamed(stream,idxn,fieldn,ft,unique,coll,allownull,uniquenull);
    'TFRE_DB_SignedIndex'   : result := TFRE_DB_SignedIndex.CreateStreamed(stream,idxn,fieldn,ft,unique,coll,allownull,uniquenull);
    'TFRE_DB_UnsignedIndex' : result := TFRE_DB_UnsignedIndex.CreateStreamed(stream,idxn,fieldn,ft,unique,coll,allownull,uniquenull);
    else
      raise EFRE_DB_PL_Exception.Create(edb_ERROR,'Unsupported streaming index class [%s]',[cn]);
  end;
end;

function TFRE_DB_MM_Index._IndexIsFullUniqe: Boolean;
begin
  result := (FUnique=true) and ((FUniqueNullVals=true) or (FAllowNull=false));
end;

function TFRE_DB_MM_Index._GetIndexStringSpec: String;
begin
  result := FCollection.CollectionName(false)+'#'+FIndexName+'('+FFieldname+')';
end;

{ TFRE_DB_CollectionTree }

constructor TFRE_DB_CollectionManageTree.Create;
begin
  FCollTree := TFRE_ART_TREE.Create;
end;

destructor TFRE_DB_CollectionManageTree.Destroy;
begin
  FCollTree.Clear;
  FCollTree.Free;
  inherited Destroy;
end;

procedure TFRE_DB_CollectionManageTree.Clear;

  procedure ClearTree(var dummy : NativeUint);
  begin
    TFRE_DB_Persistance_Collection(FREDB_PtrUIntToObject(dummy)).Free;
  end;

begin
  FCollTree.LinearScan(@ClearTree);
  FCollTree.Clear;
end;

function TFRE_DB_CollectionManageTree.NewCollection(const coll_name: TFRE_DB_NameType; out Collection: IFRE_DB_PERSISTANCE_COLLECTION; const volatile_in_memory: boolean; const pers_layer: IFRE_DB_PERSISTANCE_LAYER): TFRE_DB_Errortype;
var coll     : TFRE_DB_Persistance_Collection;
    safename : TFRE_DB_NameType;
begin
  safename := UpperCase(coll_name);
  if FCollTree.ExistsBinaryKey(@safename[1],Length(safename),dummy) then
    begin
      Collection := TFRE_DB_Persistance_Collection(dummy);
      result     := edb_EXISTS;
    end
  else
    begin
      coll := TFRE_DB_Persistance_Collection.Create(coll_name,volatile_in_memory,pers_layer);
      if FCollTree.InsertBinaryKey(@coll.UniqueName^[1],length(coll.UniqueName^),FREDB_ObjectToPtrUInt(coll)) then
        begin
          Collection := coll;
          exit(edb_OK);
        end
      else
        begin
          coll.Free;
          exit(edb_INTERNAL);
        end;
    end;
end;

function TFRE_DB_CollectionManageTree.DeleteCollection(const coll_name: TFRE_DB_NameType): TFRE_DB_Errortype;
var coll     : TFRE_DB_Persistance_Collection;
    safename : TFRE_DB_NameType;
    colli : IFRE_DB_PERSISTANCE_COLLECTION;
begin
  safename := UpperCase(coll_name);
  if FCollTree.RemoveBinaryKey(@safename[1],Length(safename),dummy) then
    begin
      Coll := TFRE_DB_Persistance_Collection(dummy);
      result     := edb_OK;
      Coll.Free;
    end
  else
    begin
      result := edb_NOT_FOUND;
    end;
end;

function TFRE_DB_CollectionManageTree.GetCollection(const coll_name: TFRE_DB_NameType; out Collection: IFRE_DB_PERSISTANCE_COLLECTION): boolean;
var coll     : TFRE_DB_Persistance_Collection;
    safename : TFRE_DB_NameType;
begin
  safename:=uppercase(coll_name);
  if FCollTree.ExistsBinaryKey(@safename[1],length(safename),dummy) then
    begin
      Collection := TFRE_DB_Persistance_Collection(dummy);
      result     := true;
    end
  else
    begin
      Result := false;
    end;
end;

procedure TFRE_DB_CollectionManageTree.ForAllCollections(const iter: TFRE_DB_PersColl_Iterator);

  function IterateColls(var dummy:NativeUInt):boolean;
  begin
    result := iter(FREDB_PtrUIntToObject(dummy) as TFRE_DB_Persistance_Collection)
  end;

begin
  FCollTree.LinearScanBreak(@IterateColls);
end;

{ TFRE_DB_Persistance_Collection }

function TFRE_DB_Persistance_Collection.IsVolatile: boolean;
begin
  result := FVolatile;
end;

function TFRE_DB_Persistance_Collection.IndexExists(const idx_name: TFRE_DB_NameType): NativeInt;
var
  i           : Integer;
  FUniqueName : TFRE_DB_NameType;
begin
  result := -1;
  FUniqueName := UpperCase(idx_name);
  for i := 0 to high(FIndexStore) do
    if FIndexStore[i].Uniquename^=FUniqueName then
      exit(i);
end;

procedure TFRE_DB_Persistance_Collection.AddIndex(const idx: TFRE_DB_MM_Index);
var high : NativeInt;
begin
  high := Length(FIndexStore);
  SetLength(FIndexStore,high+1);
  FIndexStore[high] := idx;
end;

procedure TFRE_DB_Persistance_Collection.IndexAddCheck(const obj: TFRE_DB_Object; const check_only: boolean);
var i : NativeInt;
begin
  for i:= 0 to high(FIndexStore) do
    FIndexStore[i].IndexAddCheck(obj,check_only);
end;

procedure TFRE_DB_Persistance_Collection.IndexUpdCheck(const new_obj, old_obj: TFRE_DB_Object; const check_only: boolean);
var i : NativeInt;
begin
  for i:= 0 to high(FIndexStore) do
    FIndexStore[i].IndexUpdCheck(new_obj, old_obj,check_only);
end;

procedure TFRE_DB_Persistance_Collection.IndexDelCheck(const del_obj: TFRE_DB_Object; const check_only: boolean);
var i : NativeInt;
begin
  for i:= 0 to high(FIndexStore) do
    FIndexStore[i].IndexDelCheck(del_obj,nil,check_only);
end;

constructor TFRE_DB_Persistance_Collection.Create(const coll_name: TFRE_DB_NameType; Volatile: Boolean; const pers_layer: IFRE_DB_PERSISTANCE_LAYER);
begin
 FGuidObjStore := TFRE_ART_TREE.Create;
 FName         := coll_name;
 FVolatile     := Volatile;
 FLayer        := pers_layer;
 FUpperName    := UpperCase(FName);
end;

destructor TFRE_DB_Persistance_Collection.Destroy;
var
  i: NativeInt;
begin
  for i := 0 to high(FIndexStore) do
    FIndexStore[i].Free;
  Clear;
  FGuidObjStore.Free;
  inherited Destroy;
end;

function TFRE_DB_Persistance_Collection.Count: int64;
begin
  result := FGuidObjStore.GetValueCount;
end;

function TFRE_DB_Persistance_Collection.Exists(const ouid: TGUID): boolean;
begin
  result := FGuidObjStore.ExistsBinaryKey(@ouid,SizeOf(ouid),dummy);
end;

function TFRE_DB_Persistance_Collection.Delete(const ouid: TGUID): TFRE_DB_Errortype;
begin
  try
    FLayer.DeleteObject(ouid,CollectionName(true));
  finally
    result := edb_PERSISTANCE_ERROR;
  end;
end;

procedure TFRE_DB_Persistance_Collection.Clear;
begin
  FGuidObjStore.Clear;
end;

procedure TFRE_DB_Persistance_Collection.GetAllUIDS(var uids: TFRE_DB_GUIDArray);
var cnt,maxc : NativeInt;

  procedure ForAll(var val:PtrUInt);
  var newobj : TFRE_DB_Object;
  begin
    newobj    := FREDB_PtrUIntToObject(val) as TFRE_DB_Object;
    uids[cnt] := newobj.UID;
    inc(cnt);
    assert(cnt<=maxc);
  end;

begin
  cnt  := 0;
  maxc := FGuidObjStore.GetValueCount;
  SetLength(uids,maxc);
  FGuidObjStore.LinearScan(@ForAll);
end;

function TFRE_DB_Persistance_Collection.Store(var new_obj: TFRE_DB_Object): TFRE_DB_Errortype;
begin
   result := edb_OK;
   if FVolatile then
    new_obj.Set_Volatile;
   try
     FLayer.StoreOrUpdateObject(new_obj,FName,true);
   except
     result := edb_PERSISTANCE_ERROR;
   end;
end;

// An object is allowed only once in a collection, but can be stored in multiple collections
// An object is always at least in one collection, dangling objects (without beeing in a collection) are errors
// All subobjects are stored and fetchable in the "Master" store too
// Subobjects can only be parented once (can only be part of one object), thus need to be unique

procedure TFRE_DB_Persistance_Collection.StoreInThisColl(const new_obj: TFRE_DB_Object; const checkphase: boolean);
begin
  // Check existance in this collection
  if checkphase then
    begin
      if FGuidObjStore.ExistsBinaryKey(new_obj.UIDP,SizeOf(TGuid),dummy) then
        raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'object [%s] already exists on store in collection [%s]',[new_obj.UID_String,FName]);
      IndexAddCheck(new_obj,true);
    end
  else
    begin
        IndexAddCheck(new_obj,false);
        if not FGuidObjStore.InsertBinaryKey(new_obj.UIDP,SizeOf(TGUID),FREDB_ObjectToPtrUInt(new_obj)) then
          raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'store of object [%s] in collection [%s] failed -> already exists on store after exist check ?',[new_obj.UID_String,FName]);
        new_obj.__InternalCollectionAdd(self); // Add The Colection Reference to a directly stored master or child object
        assert(length(new_obj.__InternalGetCollectionList)>0);
    end;
end;

procedure TFRE_DB_Persistance_Collection.UpdateInThisColl(const new_fld, old_fld: TFRE_DB_FIELD; const old_obj, new_obj: TFRE_DB_Object; const update_typ: TFRE_DB_ObjCompareEventType; const checkphase: boolean);
begin
  CheckFieldChangeAgainstIndex(old_fld,new_fld,update_typ,checkphase,old_obj,new_obj);
end;

procedure TFRE_DB_Persistance_Collection.DeleteFromThisColl(const del_obj: TFRE_DB_Object; const checkphase: boolean);
var _dummy : NativeUint;
       cnt : NativeInt;
begin
  if checkphase then
    begin
      if not FGuidObjStore.ExistsBinaryKey(del_obj.UIDP,SizeOf(TGuid),dummy) then
        raise EFRE_DB_PL_Exception.Create(edb_EXISTS,'object [%s] does not exist on delete in collection [%s]',[del_obj.UID_String,FName]);
      IndexDelCheck(del_obj,true);
    end
  else
    begin
     //writeln('MISSING : UPDATE INDICES!!');
     //FGuidObjStore.RemoveBinaryKey(@ouid,SizeOf(ouid),dummy);
      IndexDelCheck(del_obj,false);
      if not FGuidObjStore.RemoveBinaryKey(del_obj.UIDP,SizeOf(TGUID),_dummy) then
        raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'delete of object [%s] in collection [%s] failed -> does not exists on delete after exist check ?',[del_obj.UID_String,FName]);
      cnt := del_obj.__InternalCollectionRemove(self); // Add The Colection Reference to a directly stored master or child object
      if cnt=0 then
        begin
          // Object will be finally removed on FMasterdata Step
        end;
    end;
end;

function TFRE_DB_Persistance_Collection.CloneOutObject(const inobj: TFRE_DB_Object): TFRE_DB_Object;
begin
  inobj.Assert_CheckStoreLocked;
  inobj.Set_Store_Locked(false);
  try
   if Length(inobj.__InternalGetCollectionList)<1 then
     raise EFRE_DB_PL_Exception.Create(edb_INTERNAL,'logic failure, object has no assignment to internal collections');
   result := inobj.CloneToNewObject;
   if result = inobj then
     abort;
  finally
    inobj.Set_Store_Locked(true);
  end;
end;

function TFRE_DB_Persistance_Collection.CloneOutArray(const objarr: TFRE_DB_GUIDArray): TFRE_DB_ObjectArray;
var i:NativeInt;
begin
  SetLength(result,length(objarr));
  for i:=0 to high(objarr) do
    if not Fetch(objarr[i],result[i]) then
      raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'cloneout failed uid not found [%s]',[GFRE_BT.GUID_2_HexString(objarr[i])]);
end;

procedure TFRE_DB_Persistance_Collection.StreamToThis(const stream: TStream);
var i,cnt,vcnt : nativeint;

   procedure AllGuids(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint);
   var s:string[16];
   begin
     assert(KeyLen=16);
     SetLength(s,16);
     move(key^,s[1],16);
     stream.WriteAnsiString(s); // guid;
     inc(vcnt);
   end;

begin
  if FVolatile then
    abort;
  stream.Position:=0;
  stream.WriteAnsiString('FDBC');
  stream.WriteAnsiString(FName);
  cnt  := FGuidObjStore.GetValueCount;
  vcnt := 0;
  stream.WriteQWord(cnt);
  FGuidObjStore.LinearScanKeyVals(@AllGuids);
  assert(vcnt=cnt);
  stream.WriteQWord(length(FIndexStore));
  for i:=0 to high(FIndexStore) do
    FIndexStore[i].StreamToThis(stream);
end;

procedure TFRE_DB_Persistance_Collection.LoadFromThis(const stream: TStream);
var in_txt : String;
    cnt,i  : NativeInt;
    uid    : TGuid;
    dbo    : TFRE_DB_Object;
begin
  in_txt := stream.ReadAnsiString;
  if in_txt<>'FDBC' then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'COLLECTION STREAM INVALID : signature bad');
  in_txt := stream.ReadAnsiString;
  if in_txt<>FName then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'COLLECTION STREAM INVALID NAME DIFFERS: [%s <> %s]',[in_txt,FName]);
  cnt := stream.ReadQWord;
  //writeln('RELOADING COLLECTION ',in_txt,' / ',cnt);
  for i := 1 to cnt do
    begin
      in_txt := stream.ReadAnsiString; // guid;
      assert(Length(in_txt)=16);
      move(in_txt[1],uid,16);
      if not FLayer.Fetch(uid,dbo,true) then
        raise EFRE_DB_PL_Exception.Create(edb_ERROR,'COLLECTION LOAD / FETCH FAILED [%s]',[GFRE_BT.GUID_2_HexString(uid)]);
      if not FGuidObjStore.InsertBinaryKey(dbo.UIDP,SizeOf(TGUID),FREDB_ObjectToPtrUInt(dbo)) then
        raise EFRE_DB_PL_Exception.Create(edb_ERROR,'COLLECTION LOAD / INSERT FAILED [%s] EXISTS',[GFRE_BT.GUID_2_HexString(uid)]);
      dbo.__InternalCollectionAdd(self);
    end;
  cnt := stream.ReadQWord;
  SetLength(FIndexStore,cnt);
  for i := 0 to high(FIndexStore) do
    FIndexStore[i] := TFRE_DB_MM_Index.CreateFromStream(stream,self);
end;

function TFRE_DB_Persistance_Collection.CollectionName(const unique: boolean): TFRE_DB_NameType;
begin
  if unique then
    result := UniqueName^
  else
    result := FName;
end;

function TFRE_DB_Persistance_Collection.GetPersLayerIntf: IFRE_DB_PERSISTANCE_COLLECTION_4_PERISTANCE_LAYER;
begin
  result := self;
end;

function TFRE_DB_Persistance_Collection.Fetch(const uid: TGUID; var obj: TFRE_DB_Object): boolean;
begin
  result := FGuidObjStore.ExistsBinaryKey(@uid,SizeOf(TGuid),dummy);
  if result then
    obj := CloneOutObject(FREDB_PtrUIntToObject(dummy) as TFRE_DB_Object)
  else
    obj := nil;
end;

function TFRE_DB_Persistance_Collection.First: TFRE_DB_Object;
  procedure SetIt(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint);
  begin
    result := TFRE_DB_Object(value);
  end;
begin
 result := nil;
 FGuidObjStore.FirstKeyVal(@SetIt);
 if assigned(result) then
   result := CloneOutObject(result);
end;

function TFRE_DB_Persistance_Collection.Last: TFRE_DB_Object;
  procedure SetIt(var value : NativeUInt ; const Key : PByte ; const KeyLen : NativeUint);
  begin
    result := TFRE_DB_Object(value);
  end;
begin
  result := nil;
  FGuidObjStore.LastKeyVal(@SetIt);
 if assigned(result) then
   result := CloneOutObject(result);
end;

function TFRE_DB_Persistance_Collection.GetItem(const num: uint64): TFRE_DB_Object;
begin
  abort;
end;

function TFRE_DB_Persistance_Collection.DefineIndexOnField(const FieldName: TFRE_DB_NameType; const FieldType: TFRE_DB_FIELDTYPE; const unique: boolean; const ignore_content_case: boolean; const index_name: TFRE_DB_NameType; const allow_null_value: boolean; const unique_null_values: boolean): TFRE_DB_Errortype;
var index    : TFRE_DB_MM_Index;
begin
  if Count>0 then
    exit(edb_UNSUPPORTED); // has already entries
  result := edb_OK;
  if IndexExists(index_name)>=0 then
    exit(edb_EXISTS);
  case FieldType of
    fdbft_GUID,
    fdbft_ObjLink,
    fdbft_Boolean,
    fdbft_Byte,
    fdbft_UInt16,
    fdbft_UInt32,
    fdbft_UInt64 :
      begin
        index := TFRE_DB_UnsignedIndex.Create(index_name,fieldname,fieldtype,unique,self,allow_null_value,unique_null_values);
      end;
    fdbft_Int16,    // invert Sign bit by xor (1 shl (bits-1)), then swap endian
    fdbft_Int32,
    fdbft_Int64,
    fdbft_Currency, // = int64*10000;
    fdbft_DateTimeUTC:
      begin
        index := TFRE_DB_SignedIndex.Create(index_name,fieldname,fieldtype,unique,self,allow_null_value,unique_null_values);
      end;
    //fdbft_Real32: ;
    //fdbft_Real64: ;
    fdbft_String:
      begin
        index := TFRE_DB_TextIndex.Create(index_name,FieldName,FieldType,unique,ignore_content_case,self,allow_null_value,unique_null_values);
      end;
    //fdbft_Stream: ;
    //fdbft_Object: ;
    else exit(edb_UNSUPPORTED);
  end;
  AddIndex(index);
end;

// Check if a field can be removed safely from an object stored in this collection, or if an index exists on that field
//TODO -> handle indexed field change
procedure TFRE_DB_Persistance_Collection.CheckFieldChangeAgainstIndex(const oldfield, newfield: TFRE_DB_FIELD; const change_type: TFRE_DB_ObjCompareEventType; const check: boolean; const old_obj, new_obj: TFRE_DB_Object);
var i             : NativeInt;
    nullValExists : boolean;
    oldobj        : TFRE_DB_Object;
    newobj        : TFRE_DB_Object;
    fieldname     : TFRE_DB_NameType;
begin
  newobj := nil;
  oldobj := nil;
  if assigned(newfield) then
    begin
      newobj    := newfield.ParentObject;
      fieldname := uppercase(newfield.FieldName);
    end;
  if assigned(oldfield) then
    begin
      oldobj  := oldfield.ParentObject;
      oldobj.Assert_CheckStoreLocked;
      oldobj.Set_Store_Locked(false);
      try
        fieldname := uppercase(oldfield.FieldName);
      finally
        oldobj.Set_Store_Locked(true);
      end;
    end;
  for i := 0 to high(FIndexStore) do
    if FIndexStore[i].FUniqueFieldname=fieldname then
      begin
        case change_type of
          cev_FieldDeleted:
            begin
              oldobj.Assert_CheckStoreLocked;
              try
                oldobj.Set_Store_Locked(false);
                FIndexStore[i].IndexDelCheck(oldobj,new_obj,check);
              finally
                oldobj.Set_Store_Locked(true);
              end;
            end;
          cev_FieldAdded:
            begin
              nullValExists := FIndexStore[i].NullvalueExistsForObject(newobj);
              if nullValExists then // We need to to an index update if a nullvalue for this object is already indexed
                begin
                  if not FetchIntFromColl(newobj.UID,oldobj) then
                    raise EFRE_DB_PL_Exception.Create(edb_NOT_FOUND,'FIELDCHANGE Internal an object should be updated but was not found [%s]',[newobj.UID_String]);
                  oldobj.Assert_CheckStoreLocked;
                  try
                    oldobj.Set_Store_Locked(false);
                    FIndexStore[i].IndexUpdCheck(newobj,oldobj,check);
                  finally
                    oldobj.Set_Store_Locked(true);
                  end;
                end
              else
                FIndexStore[i].IndexAddCheck(newobj,check);
            end;
          cev_FieldChanged:
            begin
              oldobj.Assert_CheckStoreLocked;
              try
                oldobj.Set_Store_Locked(false);
                FIndexStore[i].IndexUpdCheck(newobj,oldobj,check);
              finally
                oldobj.Set_Store_Locked(true);
              end;
            end;
        end;
      end;
end;

function TFRE_DB_Persistance_Collection.GetIndexedObj(const query_value: TFRE_DB_String; out obj: TFRE_DB_Object; const index_name: TFRE_DB_NameType): boolean;
var arr   : TFRE_DB_ObjectArray;
begin
  obj := nil;
  result := GetIndexedObj(query_value,arr,index_name,true);
  if result then
    begin
      if Length(arr)<>1 then
        raise EFRE_DB_PL_Exception.create(edb_INTERNAL,'a unique index internal store contains [%d] elements!',[length(arr)]);
      obj := arr[0];
    end;
end;

function TFRE_DB_Persistance_Collection.GetIndexedObj(const query_value: TFRE_DB_String; out obj: TFRE_DB_ObjectArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean): boolean;
var arr : TFRE_DB_GUIDArray;
begin
  result := _GetIndexedObjUids(query_value,arr,index_name,check_is_unique);
  if result then
    obj := CloneOutArray(arr);
end;

function TFRE_DB_Persistance_Collection._GetIndexedObjUids(const query_value: TFRE_DB_String; out arr: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean): boolean;
var idx     : NativeInt;
    index   : TFRE_DB_MM_Index;
    key     : Array [0..CFREA_maxKeyLen] of Byte;
    keylen  : NativeInt;

begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  index := FIndexStore[idx];
  if check_is_unique and
     not index.IsUnique then
       raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] is not unique you must not use a point query',[index_name]);
  if not index.SupportsDataType(fdbft_String) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not support a query of [%s]',[index_name,CFRE_DB_FIELDTYPE[fdbft_String]]);

  (index as TFRE_DB_TextIndex).SetBinaryComparableKey(query_value,@key[0],keylen,false);
  result := index.FetchIndexedValsTransformedKey(arr,key,keylen);
end;

function TFRE_DB_Persistance_Collection.FetchIntFromColl(const uid: TGuid; var obj: TFRE_DB_Object): boolean;
begin
  result := FGuidObjStore.ExistsBinaryKey(@uid,SizeOf(TGuid),dummy);
  if result then
    obj := FREDB_PtrUIntToObject(dummy) as TFRE_DB_Object
  else
    obj := nil;
end;

function TFRE_DB_Persistance_Collection.GetIndexedUID(const query_value: TFRE_DB_String; out obj_uid: TGUID; const index_name: TFRE_DB_NameType): boolean;
var ouidarr : TFRE_DB_GUIDArray;
begin
  result:=GetIndexedUID(query_value,ouidarr,index_name,true);
  if result then
    obj_uid := ouidarr[0];
end;

function TFRE_DB_Persistance_Collection.GetIndexedUID(const query_value: TFRE_DB_String; out obj_uid: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const check_is_unique: boolean): boolean;
begin
  result:=_GetIndexedObjUids(query_value,obj_uid,index_name,check_is_unique);
end;

procedure TFRE_DB_Persistance_Collection.ForAllIndexed(var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean ; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var idx   : NativeInt;
    index : TFRE_DB_MM_Index;
begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  SetLength(guids,0);
  index := FIndexStore[idx];
  index.AppendAllIndexedUids(guids,ascending,max_count,skipfirst,only_count_unique_vals);
end;

procedure TFRE_DB_Persistance_Collection.ForAllIndexedSignedRange(const min_value, max_value: int64; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var idx   : NativeInt;
    index : TFRE_DB_MM_Index;
begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  index := FIndexStore[idx];
  if not (index is TFRE_DB_SignedIndex) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] cannot be used for an signed query, it is a [%s] index type on collection [%s]',[index_name,index.IndexTypeTxt,FName]);
  TFRE_DB_SignedIndex(index).ForAllIndexedSignedRange(min_value,max_value,guids,ascending,min_is_null,max_is_max,max_count,skipfirst,only_count_unique_vals)
end;

procedure TFRE_DB_Persistance_Collection.ForAllIndexedUnsignedRange(const min_value, max_value: QWord; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var idx   : NativeInt;
    index : TFRE_DB_MM_Index;
begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  index := FIndexStore[idx];
  if not (index is TFRE_DB_UnsignedIndex) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] cannot be used for an unsigned query, it is a [%s] index type on collection [%s]',[index_name,index.IndexTypeTxt,FName]);
  TFRE_DB_UnsignedIndex(index).ForAllIndexedUnsignedRange(min_value,max_value,guids,ascending,min_is_null,max_is_max,max_count,skipfirst,only_count_unique_vals)
end;

procedure TFRE_DB_Persistance_Collection.ForAllIndexedStringRange(const min_value, max_value: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const min_is_null: boolean; const max_is_max: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var idx   : NativeInt;
    index : TFRE_DB_MM_Index;
begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  index := FIndexStore[idx];
  if not (index is TFRE_DB_TextIndex) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] cannot be used for an text query, it is a [%s] index type on collection [%s]',[index_name,index.IndexTypeTxt,FName]);
  TFRE_DB_TextIndex(index).ForAllIndexedTextRange(min_value,max_value,guids,ascending,min_is_null,max_is_max,max_count,skipfirst,only_count_unique_vals)
end;

procedure TFRE_DB_Persistance_Collection.ForAllIndexPrefixString(const prefix: TFRE_DB_String; var guids: TFRE_DB_GUIDArray; const index_name: TFRE_DB_NameType; const ascending: boolean; const max_count: NativeInt; skipfirst: NativeInt; const only_count_unique_vals: boolean);
var idx   : NativeInt;
    index : TFRE_DB_MM_Index;
begin
  idx := IndexExists(index_name);
  if idx=-1 then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] does not exist on collection [%s]',[index_name,FName]);
  index := FIndexStore[idx];
  if not (index is TFRE_DB_TextIndex) then
    raise EFRE_DB_PL_Exception.Create(edb_ERROR,'the requested index named [%s] cannot be used for an text query, it is a [%s] index type on collection [%s]',[index_name,index.IndexTypeTxt,FName]);
  TFRE_DB_TextIndex(index).ForAllIndexPrefixString(prefix,guids,index_name,ascending,max_count,skipfirst,only_count_unique_vals);
end;

function TFRE_DB_Persistance_Collection.UniqueName: PFRE_DB_NameType;
begin
  UniqueName := @FUpperName;
end;


initialization

end.

