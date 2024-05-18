import std.io;

// Needed to load large .ngp files
#pragma pattern_limit 400000

// Needed to load deep ANIM_TRANSFORM trees
#pragma eval_depth 64

// TMHC or TMB
#define TMHC

using HierNode;

struct Ptr<PointeeTy>
{
    u32 pointerValue [[hidden]];

    if (pointerValue != 0)
    {
        PointeeTy *data : u32 @ addressof(pointerValue) [[inline]];
    }
};

struct Angle16
{
    s16 m_angle;
} [[static, format("format_angle16")]];

fn format_angle16(Angle16 angle)
{
    return std::format("{} (0x{:X})", (angle.m_angle / 32768f) * 3.1415927f, angle.m_angle);
};

struct FVECTOR4
{
    float x;
    float y;
    float z;
    float w;
} [[static, format("format_fvector4")]];

fn format_fvector4(FVECTOR4 v)
{
    return std::format("{{ x:{}, y:{}, z:{}, w:{} }}", v.x, v.y, v.z, v.w);
};

struct FVECTOR3
{
    float x;
    float y;
    float z;
} [[static, format("format_fvector3")]];

fn format_fvector3(FVECTOR3 v)
{
    return std::format("{{ x:{}, y:{}, z:{} }}", v.x, v.y, v.z);
};

struct FMATRIX4x4
{
    float m[4 * 4];
};

struct Plane
{
    FVECTOR3 norm;
    float d;
};

union QwData
{
    u128 ui128;
    u64 ui64[2];
    u32 ui32[4];
    s32 si32[4];
    u16 ui16[8];
    s16 si16[8];
    u8 ui8[16];
    s8 si8[16];
    float fVec[4];
} [[static]];

struct Rgba
{
    u8 r;
    u8 g;
    u8 b;
    u8 a;
};

union ColorUnionType
{
    u32 word;
    u8 byte[4];
    Rgba chan;
};

struct AnimationOutputBlock
{
    Ptr<float> val;
    Ptr<u8> dirty;
    Ptr<FMATRIX4x4> atMat;
};

enum HierOpcodes : u8
{
    OBJECT_NODE,
	GROUP_NODE,
	LOD_NODE,
	TRANSLATE_NODE,
	ROTATE_NODE,
#ifdef TMB
    LIGHT_NODE,
#endif
	SWITCH_NODE,
	ANIMATION_MGR_NODE,
	CONTROL_NODE,
	NULL_NODE,
	COLLISION_VOLUME_NODE,
	COLLISION_TRIGGER_NODE,
	CHARACTER_ANIMATION_NODE,
#ifdef TMB
    TERRAIN_NODE,
    TERRAIN_OBJECT_NODE,
#endif
	COLLISION_GRID,
#ifdef TMB
    PARTICLE_MGR_NODE,
#endif
	ANIM_TRANSFORM,
#ifdef TMB
    BSP_NODE,
    PARTICLE_NODE,
    PARTICLE_FIELD_NODE,
    PARTICLE_VISUAL_NODE,
#endif
	PARTICLE_EMITTER_NODE,
	ACTION_DATA_NODE,
	CHARACTER_NODE,
	CHARACTER_INSTANCE_NODE,
#ifdef TMB
    LIGHT_VOLUME_NODE,
    FOG_VOLUME_NODE,
    AMBIENT_VOLUME_NODE,
    REVERB_VOLUME_NODE,
#endif
	SCALE_NODE,
	DESTRUCTIBLE_NODE,
#ifdef TMB
    DESTRUCT_TABLE_NODE,
    ANIMATION_CONTROL_NODE,
    ANIMATION_BLEND_NODE,
#endif

#ifdef TMHC
	INSTANCE_STATE_NODE,
	SKELETON_BONE_NODE,
	SOUND_LOCATOR_NODE,
	CAMERA_NODE,
	ANIM_SCALE,
	ATTACHPT_NODE,
	POLY_COLLISION_OBJECT,
	DATA_NODE,
	LIGHT_VERT_NODE,
	ENTRY_POINT_NODE,
	NAV_MESH_NODE,
	NEWROTATE_NODE,
#endif
	LAST_NODE
};

bitfield HierHead
{
    HierOpcodes opcode : 5;
    isRelocated : 1;
    id2 : 12;
    id1 : 14;
};

enum ActOpcodes : u16
{
	ACT_GROUP,
	ACT_POOF,
	ACT_SWITCH,
	ACT_HPTEST,
	ACT_ANIM,
	ACT_TEST,
	ACT_SETPARM,
	ACT_SETPOINTER,
	ACT_DEBRIS,
	ACT_PLAYSOUND,
};

struct ActHead
{
    ActOpcodes opcode;
};

// types referenced, but not present in debug symbols
struct Root {};
struct Pool {};
struct TaskManager {};

//
// OBJECT_NODE
//
bitfield HierObjectBits
{
    nofov : 1;
    envMapped : 3;

#ifdef TMB
    dontCsLight : 1;
#endif

#ifdef TMHC
    simpleObj : 1;
#endif

    objType : 2;
    pointLight : 1;
    dirLight : 1;

#ifdef TMB
    noTODLight : 1;
    hasMorph : 1;
#endif

#ifdef TMHC
    dontShadowMe : 1;
    dontFarClip : 1;
#endif

    uvScroll : 1;

#ifdef TMB
    layered : 1;
    callback : 1;
#endif

#ifdef TMHC
    backFaceCull : 1;
    specLightMe : 1;
#endif

    sortOnFade : 1;
    alphaSort : 1;

#ifdef TMB
    numVerts : 16;
#endif

#ifdef TMHC
    numTextures : 3;
    texPktQwords : 4;
    dontCastShadow : 1;
    lightColorSet : 2;
    specAddLitMe : 1;
    future : 4;
    extendDataOff : 1;
#endif
};

struct HierObjectExt
{
    s16 uOffIdx;
    s16 vOffIdx;
    s16 rAnimIdx;
    s16 gAnimIdx;
    s16 bAnimIdx;
    s16 aAnimIdx;
    u32 pad1;
    float specIntensity;
    float pad3;
    float fogBurnThru;
    float pad2;
};

struct ObjectTexture
{
    QwData tex0;
    QwData tex1;
    QwData mip;
};

struct HierAnimSkel
{
    Ptr<HierNode> skeleton;
    Ptr<FMATRIX4x4> restPoseInv;
    u8 restPoseIdx[1];
};

struct HierObject
{
    HierHead head;
#ifdef TMB
    Ptr<u32> polyPkt;
    float sphereRadiusSqrd;
#endif
    HierObjectBits bits [[no_unique_address]];
    u32 flags;
#ifdef TMHC
    float envMapWeight;
    float scale;
    u32 texId[4];
#endif
    FVECTOR3 sphereCenter;
    float sphereRadius;
#ifdef TMB
    float uOffset;
    float vOffset;
    float fogBurnThru;
#endif

#ifdef TMHC
    FVECTOR3 obbVec1;
#endif
    float zBufferFudge;
#ifdef TMHC
    FVECTOR3 obbVec2;
    s8 packetPtrIdx;
    u8 polyPktOffset;
    s16 numVerts;
    FVECTOR3 obbVec3;
    float alphaAnim;
    QwData texCtx[bits.numTextures];
    if (bits.extendDataOff) Ptr<HierObjectExt> extendData;
#endif

#ifdef TMB
    s16 uOffIdx;
    s16 vOffIdx;
    s16 rAnimIdx;
    s16 gAnimIdx;
    s16 bAnimIdx;
    s16 aAnimIdx;
    s16 morphIdx;
    s16 padIdx;
    float redAnim;
    float greenAnim;
    float blueAnim;
    float alphaAnim;
    u16 texId[5];
    u16 numTextures;
    u32 pad2;
    float morphAnim;
    Ptr<HierAnimSkel> skeleton;
    u32 skelTransformIdx;
    u32 pad3;
    ObjectTexture gsTexCtx[numTextures];
#endif
};

//
// GROUP_NODE
//
bitfield HierGroupBits
{
    visual : 1;
    collision : 1;
    noFOV : 1;
    noHAT : 1;
    enable1P : 1;
    enable2P : 1;
    noCameraCollis : 1;
    dontFarClip : 1;
};

struct HierGroup
{
    HierHead head;
    Ptr<u32> ctx;
    u16 numKids;
    HierGroupBits bits [[no_unique_address]];
    u16 flags;
    float sphereRadiusSqrd;
    FVECTOR3 sphereCenter;
    float sphereRadius;
    Ptr<HierNode> child[numKids];
};

//
// LOD_NODE
//
struct HierLodDist
{
    float fade;
    float switchOutDis;
    Ptr<HierNode> child;
    u32 pad;
};

struct HierLod
{
    HierHead head;
    u32 numLods;
    Ptr<u32> ctx;
    u32 pad;
    FVECTOR3 lodCenter;
    float radius;
    Ptr<HierLodDist> lods[numLods];
};

//
// TRANSLATE_NODE
//
struct HierTranslate
{
    HierHead head;
    Ptr<u32> ctx;
    u32 numKids;
    Ptr<u32> actData;
    FVECTOR3 trans;
    Ptr<HierNode> child[numKids];
};

//
// ROTATE_NODE
//
struct HierRotate
{
    HierHead head;
    Ptr<u32> ctx;
    u32 numKids;
    u32 pad1;
    FMATRIX4x4 mat;
    Ptr<HierNode> child[numKids];
};

//
// LIGHT_NODE
//
bitfield HierLightBits
{
    isOn : 1;
    hasLensFlare : 1;
    hasScreenGlare : 1;
    isDirectional : 1;
    isBiDirectional : 1;
    lightsEnvironment : 1;
    lightsCSes : 1;
    lightAtInfinity : 1;
    pad : 24;
};

struct HierLight
{
    HierHead head;
    HierLightBits flag [[no_unique_address]];
    u32 flags;
    float intensity;
    float range;
    FVECTOR4 position;
    FVECTOR4 beamNormal;
    float lightRed;
    float lightGreen;
    float lightBlue;
    float beamWidth;
};

//
// SWITCH_NODE
//
struct HierSwitch
{
    HierHead head;
    Ptr<u32> ctx;
    u8 whichChild;
    u8 triggerAction;
    u8 triggerChild;
    u8 numKids;
    Ptr<HierNode> child[numKids];
};

//
// ANIMATION_MGR_NODE
//
using HierAnimCharInstance;

struct HierAnimMgr
{
    HierHead head;
    u32 numCharInstances;
    Ptr<HierAnimCharInstance> charInstance[numCharInstances];
};

//
// CONTROL_NODE
//
struct HierBsp
{
    Ptr<HierBsp> frontKid;
    Ptr<HierBsp> backKid;
    Ptr<HierBsp> coplanarKid;
    u16 matIdFront;
    u16 matIdBack;
    Plane plane;
};

struct HierCtrl
{
    HierHead head;
    Ptr<HierNode> child1;
    Ptr<HierNode> child2;
    u8 numVolumes;
    u8 collisOnly;
    u8 volType;
    u8 unused;
#ifdef TMHC
    FVECTOR4 sphere;
#endif
    Ptr<HierBsp> bspNodes[numVolumes];
};

//
// COLLISION_VOLUME_NODE
//
struct HierCollisionVolume
{
    HierHead head;

#ifdef TMB
    u16 plExclude;
    u8 matId;
    s8 useNormal;
    u32 numPlanes;
    float sphereRadiusSqrd;
#endif

#ifdef TMHC
    s16 numPlanes;
    s16 useNormal;
    u16 matId;
    u16 plExclude;
    Ptr<ActHead> actTree;
#endif
    FVECTOR3 sphereCenter;
    float sphereRadius;
#ifdef TMB
    Ptr<ActHead> actTree;
    u32 pad1;
    u32 pad2;
    u32 pad3;
#endif
    Plane planes[numPlanes];
};

//
// COLLISION_TRIGGER_NODE
//
bitfield HierCollisionTriggerBits
{
    helicopter : 1;
    weather : 1;
    disableTOD : 1;
    pad : 13;
    maxCameraHeight : 16;
};

struct HierCollisionTrigger
{
    HierHead head;
    HierCollisionTriggerBits bits;
    Ptr<HierBsp> bsp;
    s32 actionCnt;
    Ptr<HierNode> triggerAction[actionCnt];
};

//
// CHARACTER_ANIMATION_NODE
//
struct HierAnimKey
{
    float time;
    float fCoeff[4];
};

bitfield HierAnimChannelBits
{
    preInfinity : 4;
    postInfinity : 4;
    padbits : 7;
    isRelocated : 1;
};

struct HierAnimChannel
{
    s16 numKeys;
    HierAnimChannelBits bits;
    u16 dataIdx;
    HierAnimKey animKeys[numKeys];
};

bitfield HierAnimationBits
{
    autoStart : 1;
    autoLoop : 1;
    pad14 : 14;
};

enum CurveType : u8
{
    kHermite,
    kBroken,
    kPwl,
    kStatic,
    kSmooth,
    kStepped,
    kFlat,
};

enum DataType : u8
{
    kFloat,
    k16bit,
    k8bit,
};

enum InfinityType : u8
{
    kConstant,
    kLinear,
    kCycle,
    kCyclePlusOffset,
    kOscillate,
};

bitfield AnimCurve
{
    CurveType curveType : 3;
    DataType dataType : 3;
    preInfinity : 3;
    postInfinity : 3;
    InfinityType slopeType : 3;
    angular : 1;
    u16 dataIdx;
    
    if (curveType == CurveType::kStatic)
        float value;
};

struct HierAnimation
{
    HierHead head;
    float startTime;
    float endTime;
    u16 numChannels;
#ifdef TMHC
    HierAnimationBits bits [[inline]];
#endif

#ifdef TMB
    u16 firstChannelIdx;
#endif
    u16 animIdx;
#ifdef TMHC
    u16 curveOffsets[numChannels];
#endif

#ifdef TMB
    s16 soundIdx1;
    s16 soundIdx2;
    Ptr<HierAnimChannel> channels[numChannels];
#endif
};

//
// COLLISION_GRID
//
struct GridDef
{
    s16 xDim;
    s16 yDim;
    float cellSize;
    float invCellSize;
    float minX;
    float minY;
    float maxX;
    float maxY;
};

bitfield PathPtr
{
    isTrigger : 1;
    pad : 6;
    pathAddr : 25;
};

bitfield HierCollisionPathBits
{
    noHAT : 1;
    noCamera : 1;
    unused : 6;
};

struct HierCollisionPath
{
    FVECTOR3 boundBoxMin;
    FVECTOR3 boundBoxMax;
    u32 traceId;
    s8 length;
    HierCollisionPathBits bits [[inline]];
    u16 mask;
    Ptr<HierNode> path[length];
};

bitfield Cell
{
    nPaths : 10;
    firstPath : 22;
};

struct HierCollisionGrid
{
    HierHead head;
#ifdef TMHC
    GridDef gridDef;
    Ptr<PathPtr> pathPtrs;
    Ptr<HierCollisionPath> pathPool;
    Cell cells[gridDef.xDim * gridDef.yDim];
#endif
};

//
// ANIM_TRANSFORM
//
bitfield HierAnimTransBits
{
    rotX : 1;
    rotY : 1;
    rotZ : 1;
    transX : 1;
    transY : 1;
    transZ : 1;
    applyPre : 1;
    applyPost : 1;
    numKids : 8;
    visible : 15;
    visIndex : 1;
};

struct HierAnimTrans
{
    HierHead head;
#ifdef TMHC
    float transX [[no_unique_address]];
    s32 tXidx;
    float transY [[no_unique_address]];
    s32 tYidx;
    float transZ [[no_unique_address]];
    s32 tZidx;
    float rotX [[no_unique_address]];
    s32 rXidx;
    float rotY [[no_unique_address]];
    s32 rYidx;
    float rotZ [[no_unique_address]];
    s32 rZidx;
    HierAnimTransBits bits [[inline]];

    if (bits.applyPre)
        FMATRIX4x4 preMat;

    if (bits.applyPost)
        FMATRIX4x4 postMat;

    Ptr<HierNode> child[bits.numKids];
#endif
};

//
// BSP_NODE
//
struct HierBspNode
{
    HierHead head;
    float sphereRadiusSqrd;
    float sphereRadius;
    Ptr<HierBsp> bspRoot;
    FVECTOR3 sphereCenter;
    u32 pad1;
};

//
// PARTICLE_EMITTER_NODE
//
bitfield HierParticleEmitterBits
{
    isMoving : 1;
    isFading : 1;
    isFluctuating : 1;
    isAutoStart : 1;
    isActivated : 1;
    pad : 27;
};

struct HierParticleEmitter
{
    HierHead head;
    u32 particleEnum;
    float size;
    float velocity;
    FVECTOR4 position;
    float spread;
    float emissionHeading;
    float emissionPitch;
    float emissionRate;
    u32 emissionDuration;
    u32 onsetDelay;
    float emitterStretch;
    u32 particleLifetime;
    float gravity;
    float airResistance;
    u32 airResistanceTransition;
    float initialExpansionRate;
    float expansionRate;
    u32 expansionRateTransition;
    float alphaFade;
    HierParticleEmitterBits flag [[no_unique_address]];
    u32 flags;
    FMATRIX4x4 cachedOrientation;
    FVECTOR4 cachedPosition;
};

//
// ACTION_DATA_NODE
//
struct HierActionData
{
    HierHead head;
    Ptr<HierNode> child;
    Ptr<ActHead> traverseAct;
    u32 actionData[1]; // size unknown
};

//
// CHARACTER_NODE
//

//
// CHARACTER_INSTANCE_NODE
//
struct AnimChannelId
{
    u16 id;
    u16 chanIdx;
};

struct AnimChannelIdMap
{
    s32 nIds;
    AnimChannelId entries[nIds];
};

struct AnimFileReference
{
    u8 numAnims;
    u8 pad;
    u16 stringByteOffset;
    u16 animIdShortOffset;
};

struct HierAnimCharacter
{
    u16 numAnims;
    u16 numChannels;
    u8 numAnimTran;
    u8 numAnimFiles;
    u16 pad;
    Ptr<AnimFileReference> animFileRef;
    Ptr<AnimChannelIdMap> animChannelIdMap;
    Ptr<HierAnimation> animations[numAnims];
};

bitfield HierAnimCharInstanceBits
{
    disableCI : 1;
    pad : 7;
};

struct HierAnimCharInstance
{
    HierHead head;
#ifdef TMHC
    Ptr<float> animOutput;
    Ptr<Root> animRoot;
    Ptr<Pool> animPool;
    Ptr<TaskManager> taskManager;
    Ptr<Ptr<FMATRIX4x4>> animMatrixPtr;
    Ptr<Ptr<u32>> animPktPtr;
    u32 pad1;
    Ptr<HierAnimCharacter> character;
    u32 pad2;
    u8 numKids;
    u8 numBones;
    u8 numObjects;
    HierAnimCharInstanceBits bits;
    Ptr<HierNode> child[numKids];
#endif
};

//
// LIGHT_VOLUME_NODE
//
struct HierLightVolume
{
    HierHead head;
    s32 texId;
    s32 texFormat;
    Ptr<QwData> clutAddr;
    FMATRIX4x4 localToUV;
};

//
// FOG_VOLUME_NODE
//
struct HierFogVolume
{
    HierHead head;
    ColorUnionType color;
    float maxRange;
    float minRange;
    float clipRange;
    Ptr<HierLightVolume> ramp;
};

//
// AMBIENT_VOLUME_NODE
//
struct HierAmbientVolume
{
    HierHead head;
    ColorUnionType color;
    Ptr<HierLightVolume> ramp;
};

//
// REVERB_VOLUME_NODE
//
struct HierReverbVolume
{
    HierHead head;
    Ptr<HierLightVolume> ramp;
    float depth;
};

//
// SCALE_NODE
//
struct HierScale
{
    HierHead head;
    Ptr<u32> ctx;
    u32 numKids;
    u32 uniform;
    FVECTOR4 trans;
    FVECTOR3 scale;
    Ptr<HierNode> child[numKids];
};

//
// DESTRUCTIBLE_NODE
//
struct HierDestrState
{
    Ptr<HierNode> child;
    Ptr<ActHead> actions;
    u16 damageThreshold;
    u16 behaviorType;
};

struct HierDestructible
{
    HierHead head;
#ifdef TMHC
    u16 hitPoints;
    u16 hpThreshold;
    u8 numKids;
    u8 hitPointClass;
    u8 persistLevel;
    u8 pad;
    u32 stateDataOffset;
    Ptr<HierDestrState> child[numKids];
#endif
};

//
// ANIMATION_CONTROL_NODE
//
struct AnimControlNode
{
    HierHead head;
    Ptr<HierAnimation> anim;
    AnimationOutputBlock animOutput;
    u32 startField;
    float startTime;
    float deltaTime;
    float playTime;
    u32 pauseField;
    u8 active;
    u8 loop;
    u16 iterations;
    u16 chain;
    Ptr<u16> prevKey;
    Ptr<AnimControlNode> next;
    Ptr<AnimControlNode> prev;
};

//
// ANIMATION_BLEND_NODE
//
struct AnimBlendNode
{
    HierHead head;
    AnimationOutputBlock animOutput;
    Ptr<AnimBlendNode> parent_;
    Ptr<HierNode> blendFrom;
    Ptr<HierNode> blendTo;
    u8 active;
    u8 blendSamePercent;
    u16 freezeBlend;
    float weight;
    float blendTime;
    float blendAmount;
    float blendStartTime;
    float blendStartAtTime;
    float blendStartAtPercent;
};

//
// INSTANCE_STATE_NODE
//
struct HierInstanceState
{
    HierHead head;
    u32 datablockSize;
    Ptr<HierNode> child;
};

//
// SKELETON_BONE_NODE
//
struct HierSkelBone
{
    HierHead head;
    u32 numKids;
    s16 skelOutputMatIdx;
    u16 isRootNode;
    Ptr<HierNode> child;
    FMATRIX4x4 restPoseInv;
};

//
// SOUND_LOCATOR_NODE
//
struct HierSoundLocator
{
    HierHead head;
    u32 pad[3];
    QwData soundId;
};

//
// CAMERA_NODE
//
struct HierCamera
{
    HierHead head;
    u32 pad1;
    u32 pad2;
    u32 pad3;
};

//
// ANIM_SCALE
//
struct HierAnimScale
{
    HierHead head;
    u32 numKids;
    Ptr<u32> ctx;
    float visible;
    s16 vidx;
    s16 sXidx;
    s16 sYidx;
    s16 sZidx;
    s16 tXidx;
    s16 tYidx;
    s16 tZidx;
    s16 pad1;
    FVECTOR4 scale;
    FVECTOR4 translate;
    FVECTOR4 preScale;
    FVECTOR4 postScale;
    Ptr<HierNode> child[numKids];
};

//
// POLY_COLLISION_OBJECT
//
bitfield HdPolyBBoxNodeBits
{
    isLeaf : 1;
    numChildren : 4;
    firstChild : 9;
    pad : 2;
};

struct HdPolyBBoxNode
{
    s16 minBox[3];
    s16 maxBox[3];
    HdPolyBBoxNodeBits bits [[inline]];
};

struct HierPolyCollisionObject
{
    Ptr<s16> vertexPool;
    u16 numPolys;
    u16 numBBoxes;
    s32 bboxOrigin[3];
    float bboxScale;
    HdPolyBBoxNode bbox[numBBoxes];
};

struct HierPolyCollisionGroup
{
    HierHead head;
    u16 numObjs;
    u16 numMatIds;
    Ptr<u16> matIdTable;
    Ptr<HierPolyCollisionObject> hdPolyObjs[numObjs];
};

//
// DATA_NODE
//
struct HierData
{
    HierHead head;
    Ptr<HierNode> child;
    s16 dataId;
    s16 pad;
};

//
// LIGHT_VERT_NODE
//
bitfield HierLightVertBits
{
    a : 1;
    r : 5;
    g : 5;
    b : 5;
};

struct HierLightVert
{
    s16 x;
    s16 y;
    s16 z;
    HierLightVertBits bits [[inline]];
};

struct HierLightVertPool
{
    HierHead head;
    s32 nVerts;
    FVECTOR3 origin;
    float scale;
    HierLightVert verts[nVerts];
};

//
// ENTRY_POINT_NODE
//
struct HierEntryPoint
{
    HierHead head;
    Ptr<HierNode> child;
    float radius;
    s32 nPaths;
    Ptr<HierCollisionPath> paths[nPaths];
};

//
// NAV_MESH_NODE
//
struct HierNavMesh
{
    HierHead head;
    s32 nVerts;
    s32 nFaces;
    s32 pad;
    FVECTOR4 verts[nVerts];
};

//
// NEWROTATE_NODE
//
struct HierRotateNew
{
    HierHead head;
    Ptr<u32> ctx;
    Angle16 pitch;
    Angle16 roll;
    Angle16 heading;
    s16 numKids;
    FVECTOR3 trans;
    Ptr<HierNode> child[numKids];
};

//
// HierNode
//
struct HierNode
{
    HierHead head_ [[hidden, no_unique_address]];
    
    match (head_.opcode)
    {
        (HierOpcodes::OBJECT_NODE): HierObject [[inline]];
        (HierOpcodes::GROUP_NODE): HierGroup [[inline]];
        (HierOpcodes::LOD_NODE): HierLod [[inline]];
        (HierOpcodes::TRANSLATE_NODE): HierTranslate [[inline]];
        (HierOpcodes::ROTATE_NODE): HierRotate [[inline]];
    #ifdef TMB
        (HierOpcodes::LIGHT_MODE): HierLight [[inline]];
    #endif
        (HierOpcodes::SWITCH_NODE): HierSwitch [[inline]];
        (HierOpcodes::ANIMATION_MGR_NODE): HierAnimMgr [[inline]];
        (HierOpcodes::CONTROL_NODE): HierCtrl [[inline]];
        (HierOpcodes::NULL_NODE): HierHead head;
        (HierOpcodes::COLLISION_VOLUME_NODE): HierCollisionVolume [[inline]];
        (HierOpcodes::COLLISION_TRIGGER_NODE): HierCollisionTrigger [[inline]];
        (HierOpcodes::CHARACTER_ANIMATION_NODE): HierAnimation [[inline]];
    #ifdef TMB
        (HierOpcodes::TERRAIN_NODE): HierHead head;
        (HierOpcodes::TERRAIN_OBJECT_NODE): HierHead head;
    #endif
        (HierOpcodes::COLLISION_GRID): HierCollisionGrid [[inline]];
    #ifdef TMB
        (HierOpcodes::PARTICLE_MGR_NODE): HierHead head;
    #endif
        (HierOpcodes::ANIM_TRANSFORM): HierAnimTrans [[inline]];
    #ifdef TMB
        (HierOpcodes::BSP_NODE): HierBspNode [[inline]];
        (HierOpcodes::PARTICLE_NODE): HierHead head;
        (HierOpcodes::PARTICLE_FIELD_NODE): HierHead head;
        (HierOpcodes::PARTICLE_VISUAL_NODE): HierHead head;
    #endif
        (HierOpcodes::PARTICLE_EMITTER_NODE): HierParticleEmitter [[inline]];
        (HierOpcodes::ACTION_DATA_NODE): HierActionData [[inline]];
        (HierOpcodes::CHARACTER_NODE): HierHead head;
        (HierOpcodes::CHARACTER_INSTANCE_NODE): HierAnimCharInstance [[inline]];
    #ifdef TMB
        (HierOpcodes::LIGHT_VOLUME_NODE): HierLightVolume [[inline]];
        (HierOpcodes::FOG_VOLUME_NODE): HierFogVolume [[inline]];
        (HierOpcodes::AMBIENT_VOLUME_NODE): HierAmbientVolume [[inline]];
        (HierOpcodes::REVERB_VOLUME_NODE): HierReverbVolume [[inline]];
    #endif
        (HierOpcodes::SCALE_NODE): HierScale [[inline]];
        (HierOpcodes::DESTRUCTIBLE_NODE): HierDestructible [[inline]];
    #ifdef TMB
        (HierOpcodes::DESTRUCT_TABLE_NODE): HierHead head;
        (HierOpcodes::ANIMATION_CONTROL_NODE): AnimControlNode [[inline]];
        (HierOpcodes::ANIMATION_BLEND_NODE): AnimBlendNode [[inline]];
    #endif

    #ifdef TMHC
        (HierOpcodes::INSTANCE_STATE_NODE): HierInstanceState [[inline]];
        (HierOpcodes::SKELETON_BONE_NODE): HierSkelBone [[inline]];
        (HierOpcodes::SOUND_LOCATOR_NODE): HierSoundLocator [[inline]];
        (HierOpcodes::CAMERA_NODE): HierCamera [[inline]];
        (HierOpcodes::ANIM_SCALE): HierAnimScale [[inline]];
        (HierOpcodes::ATTACHPT_NODE): HierHead head;
        (HierOpcodes::POLY_COLLISION_OBJECT): HierPolyCollisionGroup [[inline]];
        (HierOpcodes::DATA_NODE): HierData [[inline]];
        (HierOpcodes::LIGHT_VERT_NODE): HierLightVertPool [[inline]];
        (HierOpcodes::ENTRY_POINT_NODE): HierEntryPoint [[inline]];
        (HierOpcodes::NAV_MESH_NODE): HierNavMesh [[inline]];
        (HierOpcodes::NEWROTATE_NODE): HierRotateNew [[inline]];
    #endif
    }
};

struct DbHeader
{
    s32 numEntryPts [[hidden]];
    Ptr<HierNode> epNode[numEntryPts] [[inline]];
};

DbHeader header @ 0 [[inline]];
