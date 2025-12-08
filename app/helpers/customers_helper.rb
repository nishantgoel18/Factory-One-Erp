module CustomersHelper
    def activity_type_icon(type)
        case type
        when 'CALL' then 'telephone'
        when 'EMAIL' then 'envelope'
        when 'MEETING' then 'people'
        when 'NOTE' then 'journal-text'
        when 'QUOTE' then 'file-earmark-text'
        when 'ORDER' then 'cart'
        when 'COMPLAINT' then 'exclamation-triangle'
        when 'VISIT' then 'geo-alt'
        when 'FOLLOWUP' then 'arrow-repeat'
        else 'activity'
        end
    end    
end
