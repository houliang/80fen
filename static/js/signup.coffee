$ ->
    $form = $ '#form-signup'
    $submit = $ ':submit', $form

    utils.form.submit($form, $submit, (jsn) ->
        if jsn.err
            alert jsn.msg
        else
            alert '成功'
            location.href = '/auth/login'
    )
