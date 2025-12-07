module WorkOrdersHelper

    def index_stats
        [
            {
                key: 'Total', value: @stats[:total], icon_class: 'anticon anticon-ordered-list', color_class: 'avatar-blue' 
            },
            {
                key: 'Not Started', value: @stats[:not_started], icon_class: 'anticon anticon-file-markdown', color_class: 'avatar-green' 
            },
            {
                key: 'Released', value: @stats[:released], icon_class: 'anticon anticon-step-forward', color_class: 'avatar-purple' 
            },
            {
                key: 'In Progress', value: @stats[:in_progress], icon_class: 'anticon anticon-play-circle', color_class: 'avatar-gold' 
            },
            {
                key: 'Completed', value: @stats[:completed], icon_class: 'anticon anticon-file-done', color_class: 'avatar-cyan' 
            },
            
        ]
    end
end
