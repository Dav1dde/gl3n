/**
 * Copyright 2011 by Robert Pasiński
 * 
 * Licensed under MIT License
 */
$(document).ready(function() {
	
    $('#childs').css('display', 'none');
	$('#modules').css('display','none');
    
	/*
	 * COLORIZE CLASSES AND STRUCTS
	 */
	 
	$('.decl').each(function(){
		var $this = $(this);
		
		var map = ['class', 'template', 'struct', 'alias'];	
		
		for(var i = 0; i <= map.length; i++)
		{			
			if($this.text().indexOf(map[i]) >= 0)
				$this.html('<span class="'+map[i]+'decl">' + $this.html() + '</span>');				
		}		
	});
	
	
	/*
	 * LISTING
	 */	
	var j = $('#childs');
		
	j.append(list($('#content > dl').children()));
	
	function list(e)
	{
		var str = '<ul>';
		e.each(function(i){
			var $this = $(this);
			
			if($this.hasClass('decl')) {
				var name = $this.find('a').html();
                if(name==null)
                    name = "this";
                    
				var prefix = '';
								
				var kw = $this.text();				
								
				if( kw.indexOf('struct') >= 0 )
				{					
					prefix = img('struct.png', 'Struct');
				}
				else if(kw.indexOf('class') >= 0)
				{
					prefix = img('class.png', 'Class');
				}
				else if(kw.indexOf('enum')  >= 0)
				{
					prefix = img('enum.png', 'Enum');
				}
				else if(kw.indexOf('template')  >= 0)
				{
					prefix = img('template.png', 'Template');
				}
				else if(kw.indexOf('alias')  >= 0)
				{
					prefix = img('alias.png', 'Alias');
				}
				else if(kw.indexOf('@property')  >= 0)
				{
					prefix = img('property.png', 'Property');
				}
				else if(kw.indexOf('(')  >= 0)
				{
					prefix = img('func.png', 'Function');
				}
				else
				{
					prefix = img('var.png', 'Variable');
				}
				
				
				str += '<li>'+prefix+'<a href="#'+name+'">'+name+'</a></li>';
			}
			else if($this.hasClass('decldd'))
			{				
				str += list($this.children('.decldd dl').children());				
			}
		});
		str += '</ul>';
		return str;
	}
	
	/*
	 * LINK FIX
	 */
	 
	 $('#modules small').each(function(){
		var name = $(this).text();
		name = name.substr(1, name.length - 2);
		
		$(this).parent().children('a').attr('href', name.replace(/\./g, '_')+'.html');
	 });	
	
	
	/*
	 * TOGGLE
	 */
	 var modules = false, jumper = false;
	 $('#childsouter h3').click(function(){
		 $('#childs').slideToggle('slow');
		 jumper = !jumper;
	 });
	 
	  $('#modulesouter h3').click(function(){
		 $('#modules').slideToggle('slow');
		 modules = !modules;
	 });
	 
	 $(window).unload(function() {
		 createCookie("modules", modules ? "1" : "0");
		 createCookie("jumper", jumper ? "1" : "0");
	 });
	 
	 $(window).load(function(){		 
		 
		 if(readCookie("modules") == "1")
			$("#modules").slideDown();
			
		 if(readCookie("jumper") == "1")
			$("#childs").slideDown();		 
	 });	 
	 
	 
	 
	 /*
	  * UTIL
	  */
	 function img(filename, title)
	 {
		 return '<img src="images/'+filename+'" alt="'+title+'" title="'+title+'" />';
	 }
	 
	 function createCookie(name,value,days) {
		if (days) {
			var date = new Date();
			date.setTime(date.getTime()+(days*24*60*60*1000));
			var expires = "; expires="+date.toGMTString();
		}
		else var expires = "";
		document.cookie = name+"="+value+expires;
	}

	function readCookie(name) {
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
		}
		return null;
	}
	
});

