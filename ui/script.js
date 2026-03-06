const SizeStyle = Quill.import('attributors/style/size');
SizeStyle.whitelist = null;
Quill.register(SizeStyle, true);

const ColorStyle = Quill.import('attributors/style/color');
Quill.register(ColorStyle, true);

const AlignStyle = Quill.import('attributors/style/align');
Quill.register(AlignStyle, true);

const quill = new Quill('#editor', {
    theme: 'snow',
    modules: {
        toolbar: [
            [{ 'header': [1, 2, 3, false] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'color': [] }, { 'background': [] }],
            [{ 'align': [] }],
            ['image', 'clean']
        ],
        clipboard: {
            matchVisual: false
        }
    }
});

quill.clipboard.addMatcher(Node.ELEMENT_NODE, (node, delta) => {
    delta.ops.forEach(op => {
        if (op.attributes) {
            if (op.attributes.size && op.attributes.size.includes('pt')) {
                let ptSize = parseFloat(op.attributes.size);
                op.attributes.size = Math.round(ptSize * 1.33) + "px";
            }
            if (['H1', 'H2', 'H3'].includes(node.tagName)) {
                op.attributes.bold = true;
            }
        }
    });
    return delta;
});

window.addEventListener('message', (event) => {
    if (event.data.action !== "open") return;

    document.body.classList.remove('hidden');

    const loc = event.data.locale || {};
    document.documentElement.lang = event.data.lang || 'fr';

    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (loc[key]) el.textContent = loc[key];
    });
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
        const key = el.getAttribute('data-i18n-title');
        if (loc[key]) el.title = loc[key];
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (loc[key]) el.placeholder = loc[key];
    });

    const title    = event.data.title   || "Untitled Document";
    const content  = event.data.content || "";
    const isLocked = (event.data.locked === true || event.data.locked === 1);

    document.getElementById('docTitle').value = title;
    quill.root.innerHTML = content;

    if (isLocked) {
        quill.enable(false);
        document.getElementById('docTitle').disabled = true;
        document.querySelector('.ql-toolbar').style.display = 'none';
        document.querySelectorAll('.btn-action').forEach(b => {
            if (!b.innerHTML.includes('fa-times')) b.style.display = 'none';
        });
    } else {
        quill.enable(true);
        document.getElementById('docTitle').disabled = false;
        document.querySelector('.ql-toolbar').style.display = 'block';
        document.querySelectorAll('.btn-action').forEach(b => b.style.display = 'flex');
    }
});

function closeUI() {
    document.body.classList.add('hidden');
    quill.setText('');
    quill.history.clear();
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function triggerAction(actionType) {
    const contentHtml = quill.root.innerHTML;
    const docTitle    = document.getElementById('docTitle').value || "Untitled";

    if (actionType === 'duplicate') {
        const modal = document.getElementById('duplicateModal');
        if (modal) modal.classList.add('hidden');
    }

    fetch(`https://${GetParentResourceName()}/doAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action:  actionType,
            content: contentHtml,
            title:   docTitle
        })
    })
    .then(resp => resp.json())
    .then(success => {
        if (success) closeUI();
    });
}

function openModal(id)  { document.getElementById(id).classList.remove('hidden'); }
function closeModal(id) { document.getElementById(id).classList.add('hidden'); }

document.onkeyup = (e) => { if (e.key === "Escape") closeUI(); };
