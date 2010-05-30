function set_show_button_title(n, title)
{
    var button = document.getElementById("hide-show-annotations-button-" + String(n));
    button.innerHTML = title;
}

function show_annotations(n)
{
    var box = document.getElementById("annotations-inner-" + String(n));
    if (box.style.display == 'none' || box.style.display == '')
    {
        box.style.display = 'block';
        set_show_button_title(n, 'Hide');
    }
    else
    {
        box.style.display = 'none';
        set_show_button_title(n, 'Show');
    }
}


function add_annotation(n)
{
    var box = document.getElementById("annotations-inner-" + String(n));
    var addBox = document.getElementById("add-annotation-box-" + String(n));

    var boxIsVisible = box.style.display != 'none' && box.style.display != '';
    var addBoxIsVisible = addBox.style.display != 'none' && addBox.style.display != '';

    if (boxIsVisible && addBoxIsVisible)
    {
        //Hide addBox
        addBox.style.display = 'none';
    }
    else
    {
        //Show addBox
        box.style.display = 'block';
        addBox.style.display = 'block';

        set_show_button_title(n, 'Hide');
    }
}
function create_annotation(n, isPublic)
{
    var button = document.getElementById("hide-show-annotations-button-" + String(n));
    button.style.display = 'block';

    var docURLField = document.getElementById("annotation-url-" + String(n));

    var annotationTextArea = document.getElementById("annotation-text-area-" + String(n));

    if (!annotationTextArea.value)
    {
        window.windowScriptController.beep();
        return;
    }

    window.windowScriptController.createAnnotation(docURLField.value, annotationTextArea.value, isPublic);
}