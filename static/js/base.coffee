window.json =
    dumps: JSON.stringify
    loads: JSON.parse

window.utils =
    form:
        is_blocked: ($btn) ->
            'blocked' == $btn.data 'block'

        block: ($btn, txt) ->
            $btn.data(
                block: 'blocked',
                val: $btn.val() || $btn.text()
            ).addClass('disabled')
            label = txt || '稍等片刻...'
            if $btn.val().length == 0
                $btn.text label  # a, button标签
            else
                $btn.val label  # input标签

        unblock: ($btn) ->
            if not utils.form.is_blocked($btn)
                return
            $btn.data('block', null).removeClass 'disabled'
            label = $btn.data 'val'
            if $btn.val().length == 0
                $btn.text label
            else
                $btn.val label

        submit: ($form, $btn, success_callback, before_callback) ->
            f = utils.form
            $form.submit(->
                if false == (before_callback || -> true)()
                    return false
                $form.ajaxSubmit(
                    beforeSubmit: ->
                        if f.is_blocked($btn)
                            return false
                        f.block $btn
                    success: (jsn) ->
                        f.unblock $btn
                        success_callback jsn
                    error: ->
                        f.unblock $btn
                        alert '超时，请刷新后再试。'
                )
                return false
            )
