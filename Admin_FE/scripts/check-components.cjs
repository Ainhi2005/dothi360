const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const ts = require('typescript');
const React = require('react');
const { MemoryRouter } = require('react-router-dom');
const { renderToStaticMarkup } = require('react-dom/server');
for (const extension of ['.ts', '.tsx']) require.extensions[extension] = (module, filename) => {
  const source = fs.readFileSync(filename, 'utf8');
  const output = ts.transpileModule(source, { compilerOptions: {
    target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.CommonJS,
    jsx: ts.JsxEmit.ReactJSX, esModuleInterop: true,
  }}).outputText;
  module._compile(output, filename);
};
const noop = () => {};
function check(feature, name, model, expected) {
  const Component = require(path.resolve(__dirname, `../src/features/${feature}/components/${name}.tsx`))[name];
  const html = renderToStaticMarkup(React.createElement(MemoryRouter, null, React.createElement(Component, { model })));
  for (const text of expected) assert.ok(html.includes(text), `${name}: thiếu ${text}`);
  console.log('PASS', name);
}
const assignment = { id:'a', incident_id:'i', incident_type_name:'Cột đèn', description:'Cột đèn nghiêng', incident_status:'ASSIGNED', status:'ASSIGNED', department_id:'d', department_name:'Đơn vị thử', priority_level:'HIGH', assigned_at:'2026-11-20T00:00:00Z' };
const base = {
  data:[assignment], loading:false, error:'', filter:'ALL', selected:assignment,
  departments:[{id:'d',name:'Đơn vị thử'}], officers:[], filteredOfficers:[],
  selectedDeptId:'d', selectedOfficerId:'', reason:'Kiểm tra hiện trường', approvingId:null,
  setFilter:noop,setSelected:noop,setSelectedDeptId:noop,setSelectedOfficerId:noop,setReason:noop,
  load:noop,handleApproveAi:noop,openReassignModal:noop,handleConfirmAssignment:noop,
};
check('assignments','AssignmentSummary',base,['Chưa phân công']);
check('assignments','AssignmentList',base,['Cột đèn nghiêng']);
check('assignments','AssignmentDialog',base,['Phân công cán bộ xử lý','Đơn vị thử']);
const incident = {...base, data:{id:'i',status:'PENDING_VERIFICATION',description:'Cột đèn nghiêng',updates:[],media:[],ai_analysis:{reason:'Có nguy cơ',recommended_action:'Kiểm tra hiện trường'}},
 verifying:false,verificationNote:'Đã kiểm tra',setVerificationNote:noop,verify:noop,
 analyzing:false,analyzeMsg:'',handleAiAnalyze:noop,modalOpen:true,setModalOpen:noop,
 assignReason:'Kiểm tra hiện trường',setAssignReason:noop,assigning:false,assignmentError:'',
};
check('incidents','IncidentVerificationPanel',incident,['nghiệm thu']);
check('incidents','IncidentAnalysisPanel',incident,['AI']);
check('incidents','IncidentTimeline',incident,['Lịch sử xử lý']);
check('incidents','IncidentAssignmentDialog',incident,['Đơn vị thử']);

incident.openAssignModal = noop;
incident.handleApproveAi = noop;
check('incidents','IncidentAssignmentPanel',incident,['Điều phối']);
