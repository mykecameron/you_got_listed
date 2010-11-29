module YouGotListed
  class Listings < Resource
    
    def search(params = {})
      params[:page_count] ||= 20
      params[:page_index] ||= 1
      params[:sort_name] ||= "rent"
      params[:sort_dir] ||= "asc"
      params[:detail_level] ||= 2
      SearchResponse.new(self.client.class.get('/rentals/search.php', :query => params), self.client, params[:page_count])
    end
    
    def featured(params = {})
      #params.merge!(:featured => 1)
      search(params)
    end
    
    def find_by_id(listing_id)
      params = {:listing_id => listing_id, :detail_level => 2}
      response = SearchResponse.new(self.client.class.get('/rentals/search.php', :query => params), self.client, 20, false)
      (response.success? && response.properties.size > 0) ? response.properties.first : nil
    end
    
    def find_all(params = {})
      params[:page_count] ||= 20
      all_listings = []
      
      response = search(params)
      if response.success?
        all_listings << response.ygl_response.properties
        total_pages = (response.ygl_response.total.to_i/params[:page_count].to_f).ceil
        if total_pages > 1
          (2..total_pages).each do |page_num|
            resp = search(params.merge(:page => page_num))
            if resp.success?
              all_listings << resp.properties
            end
          end
        end
      end
      all_listings.flatten
    end
    
    class SearchResponse < YouGotListed::Response
      
      attr_accessor :limit, :paginator_cache, :client
      
      def initialize(response, client, limit = 20, raise_error = true)
        super(response, raise_error)
        self.limit = limit
        self.client = client
      end
      
      def properties
        return [] if self.ygl_response.listings.blank?
        props = []
        if self.ygl_response.listings.listing.is_a?(Array)
          self.ygl_response.listings.listing.each do |listing|
            props << YouGotListed::Listing.new(listing, self.client)
          end
        else
          props << YouGotListed::Listing.new(self.ygl_response.listings.listing, self.client)
        end
        props
      end
      
      def paginator
        paginator_cache if paginator_cache
        self.paginator_cache = WillPaginate::Collection.create(
          (self.ygl_response.page_index ? self.ygl_response.page_index : 1), 
          self.limit, 
          (self.ygl_response.total ? self.ygl_response.total : properties.size)) do |pager|
          pager.replace properties
        end
      end
    end
    
  end
end
