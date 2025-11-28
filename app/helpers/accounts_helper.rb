module AccountsHelper
    def badge_color_on_account_type(acc)
        if acc.account_type == 'ASSET'
            'bg-success'
        elsif acc.account_type == 'LIABILITY'
            'bg-warning'
        elsif acc.account_type == 'EQUITY'
            'bg-info'
        elsif acc.account_type == 'REVENUE'
            "bg-primary"
        else
            'bg-secondary'
        end
    end

    def total_assets
        @accounts.select{|a| a.account_type == 'ASSET'}.map{|a| a.current_balance}.sum
    end

    def total_liabilities
        @accounts.select{|a| a.account_type == 'LIABILITY'}.map{|a| a.current_balance}.sum
    end

    def total_equity
        @accounts.select{|a| a.account_type == 'EQUITY'}.map{|a| a.current_balance}.sum
    end

end
