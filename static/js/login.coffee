$ ->
    $form = $ '#form-login'
    $submit = $ ':submit', $form

    utils.form.submit($form, $submit, (jsn) ->
        if jsn.err
            alert jsn.msg
        else
            next = $form.data 'next'
            if next.indexOf('/auth/') > -1
                next = '/'
            location.href = next
    )
