<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProctorEventRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'event_type' => 'required|in:alt_tab,app_background,window_blur,fullscreen_exit,window_resize,window_maximize,window_unmaximize,window_close_attempt',
            'platform' => 'required|string',
            'device_info' => 'required|string',
            'timestamp' => 'required|date',
            'remark' => 'nullable|string',
        ];
    }
}
