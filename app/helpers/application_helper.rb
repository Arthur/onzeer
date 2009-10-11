# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def cover_img_tag(record_with_cover, size=40)
    if record_with_cover.amazon_asin
      content_tag(:img, nil, :src => "http://ec1.images-amazon.com/images/P/#{record_with_cover.amazon_asin}.01.MZZZZZZZ.jpg", :height => size, :width => size)
    elsif record_with_cover.cover
      content_tag(:img, nil, :src => record_with_cover.public_cover_path, :height => size)
    else
      content_tag(:img, nil, :src => 'images/unknow_cover.png', :height => size)
    end
  end

  def album_div(album)
    content_tag(:div,
      cover_img_tag(album) +
      content_tag(:div, content_tag(:span, h(album.artist), :class => 'artist') + link_to(h(album.name), album_path(album), :class => 'album_name')),
      :class => 'cover_album')
  end

end
