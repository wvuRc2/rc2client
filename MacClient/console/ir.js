//test functions that will eventually be replaced
function executeConsoleInput() {
	var inputElem = document.getElementById('consoleTextField');
	var txt = inputElem.value;
	rserver.execute(txt);
}

function executeCurrentScript() {
	
}

//calling uniqueID() returns a unique id for this DOM
var uniqueID = function() {
	var id=100;
	return function() {
		return id++;
	}
}();

//add some convience methods
String.prototype.startsWith = function(str) {return (this.match("^"+str)==str);}
String.prototype.trim = function(){return (this.replace(/^[\s\xA0]+/, "").replace(/[\s\xA0]+$/, ""))}
String.prototype.endsWith = function(str) {return (this.match(str+"$")==str)}


var iR = {};

iR.cmdHistory = new Array();
iR.cmdIdx = 0;
iR.handlingAltKey = false;
iR.fileTree = {};
iR.displayedDir = {};
iR.selectionStart = 0;
iR.selectionEnd = 0;
iR.userid = 0;
iR.settings = {maxHistLen: 20}
iR.graphFileUrl = 'graph.png';

iR.StatTabArray = function StatTabArray() {
	this.size = function() {
			var size=0, key;
			for (key in this) {
//				if (key.match(/^tab/) && this.hasOwnProperty(key)) size++;
				if (key.startsWith("tab") && this.hasOwnProperty(key)) size++;
			}
			return size;
		},
	this.firstTab = function() {
			var key;
			for (key in this) {
				if (key.startsWith("tab")) {
					return this[key];
				}
			}
			//should never get here
			return undefined;
		}
};

iR.statTabs = new iR.StatTabArray();

iR.StatDocTab = (function() {
	var nextId = 1;

	return function() {
		this.tabId = nextId++;
		this.content = "";
		this.savedContent = "";
		this.curFileId = 0;
		this.idString = "tab" + this.tabId;
		
		var headList = document.getElementById('statDocTabList');
		var newHeader = document.createElement('li');
		var newLink = document.createElement('a');
		newHeader.setAttribute('id', 'tab' + this.tabId);
		newLink.setAttribute('href', '#');
		newLink.setAttribute('onClick', "iR.selectTab(" + this.tabId + ");return false;");
		newLink.innerHTML = "Tab " + this.tabId;
		var closeLink = document.createElement('a');
		closeLink.setAttribute('href', '#');
		closeLink.setAttribute('class', 'closeBox');
		closeLink.setAttribute('onClick', "iR.closeTab(" + this.tabId + ");return false;");
		closeLink.innerHTML = "&nbsp;";
		newHeader.className = 'tabListItem';
		newHeader.appendChild(newLink);
		newHeader.appendChild(closeLink)
		headList.appendChild(newHeader);
		this.tabLiEleemnt = newHeader;
	};
}());

iR.StatDocTab.prototype = (function() {
	return {
		showId: function() {
			console.log('id = ' + this.tabId);
		},
		selectTab: function(aTabId) {
			$('.selected').removeClass('selected');
			$('#tab' + aTavId).addClass('selected');
		}
	};
}());

iR.currentTimestamp = function() {
	var now = new Date();
	var hour = now.getHours()
	if (hour < 10)
		hour = "0" + hour
	var mins = now.getMinutes()
	if (mins < 10)
		mins = '0' + mins;
	var seconds = now.getSeconds()
	if (seconds < 10)
		seconds = "0" + seconds
	return (1+now.getMonth()) + '/' + now.getDate() + '/' + (now.getYear()+1900) +	' ' +
		hour + ':' + mins + ':' + seconds;
}

iR.setUserid = function(userid) {
	iR.userid = userid;
//	var str = '<span class="statusText">Logged in as user ' + userid + '</span>\n'
//	iR.appendConsoleText(str)
}

iR.userJoinedSession = function(login, userid) {
	var html = '<span class="statusText">[' + iR.currentTimestamp() + '] ' + login + ' has joined the session</span>\n'
	iR.appendConsoleText(html)
}

iR.userLeftSession = function(login, userid) {
	var html = '<span class="statusText">[' + iR.currentTimestamp() + '] ' + login + ' has left the session</span>\n'
	iR.appendConsoleText(html)
}

iR.echoInput = function(txt, username, userid) {
	var html = '\n<span class="inputText">';
//	if (userid != iR.userid)
		html += '<span class="inputUser">' + username + ':</span> '
	html += txt + "</span>\n"
	iR.appendConsoleText(html)
}

iR.cmdHistoryScrollUp = function() {
	if (iR.cmdHistory.length > 1) {
		var nxtIdx = iR.cmdIdx;
		if (nxtIdx < 0) {
			nxtIdx = iR.cmdHistory.length - 1;
		}
		document.getElementById('consoleTextField').value = iR.cmdHistory[nxtIdx];
		iR.cmdIdx = nxtIdx-1;
	}
}

iR.cmdHistoryScrollDown = function() {
	if (iR.cmdHistory.length > 1) {
		var nxtIdx = iR.cmdIdx;
		if (nxtIdx >= iR.cmdHistory.length)
			nxtIdx = 0;
		document.getElementById('consoleTextField').value = iR.cmdHistory[nxtIdx];
		iR.cmdIdx = nxtIdx+1;
	}
}

iR.consoleKeyDown = function(e) {
	if (e.altKey && !iR.handlingAltKey) {
		iR.handlingAltKey = true;
		iR.cmdIdx = iR.cmdHistory.length - 1;
	}
}

iR.consoleKeyUp = function(e) {
	if (iR.handlingAltKey) {
		switch (e.keyCode) {
			case 38:
				iR.cmdHistoryScrollUp();
				break;
			case 40:
				iR.cmdHistoryScrollDown();
				break;
		}
		if (!e.altKey)
			iR.handlingAltKey = false;
	}
}

iR.previewImage = function(imgGroup) {
	var elems = $(imgGroup).find("a").get()
	Rc2.preview(imgGroup, elems);
}

iR.closeImagePreview = function(imgGroup) {
	Rc2.closePreview(imgGroup);
}

iR.appendImages = function(imgArray) {
	var ic = document.createElement('div')
	var divname = 'img' + new Date().getTime()
	ic.setAttribute('id', divname)
	$(ic).addClass("imgGroup")
	$(ic).mouseenter(function() {iR.previewImage(this); })
	$(ic).mouseleave(function() {iR.closeImagePreview(this); })
	for (var i=0; i < imgArray.length; i++) {
		var ispan = document.createElement('span');
		ispan.setAttribute('class', 'Rimg');
		var elem = document.createElement('img');
		elem.setAttribute('src', iR.graphFileUrl);
		elem.setAttribute('height', 32);
		elem.setAttribute('width', 32);
		var anchorElem = document.createElement("a");
		anchorElem.setAttribute("href", imgArray[i]);
		anchorElem.appendChild(elem);
		anchorElem.setAttribute('class', 'genImg');
		ispan.appendChild(anchorElem);
		ic.appendChild(ispan)
	}
	var outdiv = document.getElementById('consoleOutputGenerated');
	outdiv.appendChild(ic)
	outdiv.scrollTop = outdiv.scrollHeight;
	$('#' + divname + " a.genImg").lightBox({fixedNavigation:true});
}

iR.restoreConsoleHTML = function(html) {
	try {
		$('#consoleOutputGenerated').append(html)
			var outdiv = document.getElementById('consoleOutputGenerated');
			outdiv.scrollTop = outdiv.scrollHeight;
	} catch (e) {
		return e.description
	}
}

iR.appendConsoleText = function(text) {
		var outdiv = document.getElementById('consoleOutputGenerated');
		var str = outdiv.innerHTML + text;
		outdiv.innerHTML = str;
		outdiv.scrollTop = outdiv.scrollHeight;
}

iR.showImageForTab = function(imgUrl, theTab) {
	theTab.updateDefaultImage(imgUrl);
}

iR.handleServerError = function(msg) {
	iR.appendConsoleText('<div class="statusText">&lt;&lt;' + msg + "&gt;&gt;</div>\n")
}

iR.clearConsole = function() {
	var div = document.getElementById('consoleOutputGenerated');
	div.innerHTML = ''
}

iR.toggleDataFrame = function(dfid) {
	var tbody = jQuery("#df" + dfid)
	var imgdiv = jQuery("#dfl" + dfid)
	var img = jQuery("img", imgdiv)[0]
	if (img.src.endsWith('/img/toggleOpen.png')) {
		img.src = '/img/toggleClosed.png';
		tbody.fadeOut(700, function() {
			imgdiv.find('span').css('visibility', 'visible')
		})
	} else {
		img.src = '/img/toggleOpen.png';
		imgdiv.find('span').css('visibility', 'hidden')
		tbody.fadeIn(700)
	}
}

iR.arrayRowsToTableRows = function(dataArray) {
	var txt = ''
	var maxlen=0
	var isDF=false
	//this works for simple, not complex. if any decendent is a data frame, we need to limit to two columns
	for (var i=0; i < dataArray.length; i++) {
		var x = dataArray[i].toString()
		if (x.length > maxlen)
			maxlen = x.length
		if (dataArray[i].hasOwnProperty("type") && dataArray[i]['type'] == 'dataframe')
			isDF=true
	}
	var numCols = Math.floor(60 / maxlen)
	if (numCols < 1)
		numCols = 1
	if (numCols > dataArray.length)
		numCols = dataArray.length
	if (isDF)
		numCols = 1
	var i=0
	for (i=0; i < dataArray.length; i++) {
		if (i % numCols == 0) {
			if (i > 0) txt += "</tr>\n"
			txt += "<tr>"
		}
		if (dataArray[i].substring || dataArray[i].toFixed)
			txt += "<td>" + dataArray[i] + "</td>"
		else
			txt += "<td>" + iR.formatComplex(dataArray[i]) + "</td>"
	}
	while (i++ % numCols > 0)
		txt += '<td>&nbsp;</td>'
	txt += "</tr>\n"
	return txt
}

iR.formatMatrix = function(theMatrix) {
	var numRows = theMatrix['rows']
	var numCols = theMatrix['cols']
	var data = theMatrix['data']
	var html = '<table class="ir-expvec ir-mx">'
	var haveRowHeaders = theMatrix.hasOwnProperty("rownames")
	var haveColHeaders = theMatrix.hasOwnProperty("colnames") && theMatrix['colnames'].length == numCols
	if (haveColHeaders) {
		html += '<thead><tr>'
		if (haveRowHeaders) html += '<th>&nbsp;</th>'
		for (var i=0; i < numCols; i++)
			html += '<th>' + theMatrix['colnames'][i] + '</th>'
		html += '</tr></thead>\n'
	}
	html += '<tbody>'
	var rowNum=0
	for (var i=0; i < data.length; i++) {
		if (i % numCols == 0) {
			if (i > 0) html += '</tr>\n'
			html += '<tr>'
			if (haveRowHeaders) html += '<th>' + theMatrix['rownames'][rowNum++] + '</th>'
		}
		html += '<td>' + data[i] + '</td>'
	}
	html == '</tr>\n</tbody></table>'
	return html
}

iR.formatDataFrame = function(theFrame) {
	var colTitles = theFrame['colTitles']
	var rowTitles = theFrame['rowTitles']
	var colData = theFrame['rows']
	var id = uniqueID().toString()
	var dfid = 'df' + id
	var html = '<table class="ir-expvec ir-df" id="' + dfid + '">'
	var headRow = '<thead><tr>'
	var capt = '<div class="ir-df-label" id="dfl' + id + '"><img src="/img/toggleOpen.png" width="10" heigh="10" onclick="iR.toggleDataFrame(\'' + id + '\')"><span style="visibility:hidden">'
	if (rowTitles) headRow += '<th>&nbsp;</th>'
	for (var i=0; i < colTitles.length; i++) {
		headRow += '<th class="ir-df-ch">' + colTitles[i] + '</th>'
		if (i > 0) capt += ','
		capt += colTitles[i]
	}
	headRow += '</tr></thead>\n'
	capt += '</span></div>'
	html = capt + html + headRow + '<tbody id="dfb' + id.toString() + '">'
	var rowCount = colData[0].length
	for (var i=0; i < rowCount; i++) {
		html += '<tr>'
		if (rowTitles) html += '<th class="ir-df-rh">' + rowTitles[i] + "</th>"
		for (var j=0; j < colData.length; j++)
			html += '<td>' + colData[j][i] + '</td>'
		html += '</tr>\n'
	}
	html += '</tbody></table>\n'
	return html
}

iR.formatHash = function(theHash) {
	if (theHash['type'] == 'dataframe')
		return iR.formatDataFrame(theHash)
	var html = ''
	for (key in theHash) {
		if (theHash.hasOwnProperty(key)) {
			//it is a value to output
			var val = theHash[key]
			html += "<tr><th>" + key + '</th><td class="ir-expvecnest">'
			html += iR.formatList(val)
			html += "</td></tr>\n"
		}
	}
	return html
}

iR.formatList = function(theList) {
	var html = '<table class="ir-expvec">'
	if (theList.substring) {
			//it is a string, not a list. assume already wrapped appropriately
			return theList
	} else if (theList.toFixed) {
		//a number. not a list
		return "<td>" + theList + "</td>";
	} else if (theList instanceof Array) {
		//it is an array
		if (theList.length == 1 && (theList[0].substring || theList[0].toFixed))
			return theList[0].toString()
		html += iR.arrayRowsToTableRows(theList)
	} else {
		//it is a hash
		if (theList['type'] == 'matrix') {
			return iR.formatMatrix(theList)
		} else if (theList['type'] == 'dataframe') {
			return iR.formatDataFrame(theList)
		}
		html += iR.formatHash(theList)
	}
	html += '</table>'
	return html
}

iR.formatComplex = function(dataArray) {
	if (dataArray.length == 1) 
		return iR.formatList(dataArray[0])
	else
		return iR.formatList(dataArray)
}

iR.appendComplexResults = function(dataArray) {
	console.log(dataArray)
	var outdiv = document.getElementById('consoleOutputGenerated');
	var html = iR.formatComplex(dataArray)
	var newElem = jQuery(html)
	newElem.addClass("ir-rt-root");
	newElem.appendTo(jQuery("#consoleOutputGenerated"))
	//all the nested tables are now marked as such
	jQuery(".ir-expvec", newElem).addClass("subtable")
	//set all dataframe labels to be the width of their table
	jQuery(".ir-df-label").each(function(idx) {
			jQuery(this).css('width', jQuery(this).next(".ir-df").css('width'));
	});
	outdiv.scrollTop = outdiv.scrollHeight;
}

iR.appendResults = function(dataArray) {
	var txt = '<table class="ir-expvec">'
	if (typeof dataArray[0] != "string")
		return this.appendNumericResults(dataArray)
	txt += iR.arrayRowsToTableRows(dataArray)
	txt += "</table>"
	var outdiv = document.getElementById('consoleOutputGenerated');
	outdiv.innerHTML += txt
}

//eventually this should align the decimal places. for now, we just do it as strings
iR.appendNumericResults = function(dataArray) {
	var txt = '<table class="ir-expvec">'
	var maxlen=0
	for (var i=0; i < dataArray.length; i++) {
		var x = dataArray[i].toString()
		if (x.length > maxlen)
			maxlen = x.length
	}
	var numCols = Math.floor(60 / maxlen)
	if (numCols < 1)
		numCols = 1
		if (numCols > dataArray.length)
			numCols = dataArray.length
	var i=0
	for (i=0; i < dataArray.length; i++) {
		if (i % numCols == 0) {
			if (i > 0) txt += "</tr>\n"
			txt += "<tr>"
		}
		txt += "<td>" + dataArray[i] + "</td>"
	}
	while (i++ % numCols > 0)
		txt += '<td>&nbsp;</td>'
	txt += "</tr>\n"
	txt += "</table>"
	iR.appendConsoleText(txt)
}

iR.executeConsoleCommand = function() {
	var cmdElem = document.getElementById('consoleTextField');
	var cmd = cmdElem.value
	iR.cmdHistory.push(cmd);
	rserver.executeScript(cmd);
	cmdElem.value = '';
	iR.cmdIndex = iR.cmdHistory.length-1;
	//add to history tab
	var dispVal = cmd
	if (dispVal.length > 15)
		dispVal = dispVal.substr(0, 15) + '…'
	var aElem = $('<a href="#">' + dispVal + "</a>")
	var liElem = $('<li></li>')
	aElem.click(function(e) { e.preventDefault(); cmdElem.value = cmd; $('#consoleTextField').focus()})
	aElem.appendTo(liElem)
	liElem.prependTo($('#histTable'))
	if (iR.settings.maxHistLen > 0 && $('#histTable').children().length > iR.settings.maxHistLen)
		$('#histTable').children().filter(":last").remove()
}

iR.executeCurrentTab = function() {
	var txt = $("#scriptArea").val()
	var inp = $("#scriptArea")[0]
	if ((inp.selectionEnd - inp.selectionStart) > 0) {
		txt = txt.substring(inp.selectionStart, inp.selectionEnd)
	}
	rserver.executeScript(txt);
}

iR.createDefaultStatTab = function() {
	var newTab = new iR.StatDocTab();
	iR.statTabs[newTab.idString] = newTab;
	var li = newTab.tabLiEleemnt;
	li.setAttribute('class', 'tabListItem selected');
	iR.curTab = newTab;
}

iR.newFileNameChanged = function() {
	if (! $('#fileNameField').val().match('\.(R|RnW|txt)$')) {
		$('#SaveNewFile').attr('disabled', true)
	} else {
		$('#SaveNewFile').removeAttr('disabled')
	}
}

iR.completeNewFileSave = function(newName) {
	$('#fileNameField').attr('disabled', true)
	$('#SaveNewFile').attr('disabled', true)
	jQuery.ajax({
		type:'POST',
		url: '/fd/files/new',
		data: {name: newName, content: iR.curTab.content, userid: iR.userid},
		success: function(data) {
			$('#nameFile').dialog('close')
			iR.curTab.curFileId = data['id']
			$("#" + iR.curTab.idString).children().first().html(data['name'])
			iR.curTab.savedContent = $('#scriptArea').val()
			rserver.sendFileUpdateNotification(iR.curTab.curFileId)
		},
		error: function() {
			$('#nameFileError').text('Unknown Error')
		},
		statusCode: {
			403: function() {
				//forbidden
				$('#nameFileError').text('Permission denied')
			},
			409: function() {
				//confict with name
				$('#nameFileError').text('A file already exists with that name')
			}
		},
		complete: function() {
			$('#fileNameField').removeAttr('disabled')
			$('#SaveNewFile').removeAttr('disabled')
		}
	})
}

iR.saveCurrentTab = function() {
	//save the data
	iR.curTab.content = $("#scriptArea").val()
	//see if this file exists
	if (iR.curTab.curFileId == 0) {
		//we need to prompt them to name the file
		$("#nameFile").dialog('open')
	} else {
		jQuery.ajax({
			type:'POST',
			url: '/fd/files/' + iR.curTab.curFileId,
			data: {content: iR.curTab.content },
			success: function(data) {
					showStatus("File saved", 6000)
					iR.curTab.savedContent = $('#scriptArea').val()
					rserver.sendFileUpdateNotification(iR.curTab.curFileId)
				},
			error: function(jq) {
					showStatus("Unknown error saving file", 10000)
			},
			statusCode: {
				403: function() {
					showStatus("Permission denied", 10000)
				}
			}
		})
	}
}

iR.saveCurrentTabAs = function() {
	//save the data
	iR.curTab.content = $("#scriptArea").val()
	//we need to prompt them to name the file
	$('#fileNameField').text($("#" + iR.curTab.idString).children().first())
	$("#nameFile").dialog('open')
}

iR.displayImportDialog = function() {
	$("#importDialog").dialog('open')	 
}

iR.checkImportFile = function(e) {
	var str = $("#fileInput").val();
	if (!str.endsWith(".R") && !str.endsWith(".RnW") && !str.endsWith(".txt")) {
		$('#importFileError').text('Files must be of type .R, .RnW, or .txt')
		$("#fileInput").val('')
		$('#importSubmit').attr('disabled', true)
	} else
		$('#importSubmit').removeAttr('disabled')
}

iR.handleImportResponse = function(e) {
	var str = frames['fileUploadFrame'].document.getElementsByTagName("body")[0].innerHTML
	if (str.startsWith("<pre"))
		str = $('pre', $('#fileUploadFrame').contents()).text()
	var data = JSON.parse(str);
	if (data['status'] == 'success') {
		$('#importDialog').dialog('close')
		iR.loadFile(data['id'], data['name'], true)
		rserver.sendFileUpdateNotification(data['id'])
	} else {
		$('#importFileError').text(data['msg'])
	}
	
}

iR.closeTab = function(aTabId) {
	if (iR.statTabs.size() < 2) {
		alert('You can not close the last open tab');
		return;
	}
	var theTab = iR.statTabs["tab" + aTabId];
	theTab.tabLiEleemnt.parentNode.removeChild(theTab.tabLiEleemnt);
	delete iR.statTabs["tab" + aTabId];
	if (theTab == iR.curTab) {
		//find the next tab
		var editArea = document.getElementById('scriptArea');
		iR.curTab = iR.statTabs.firstTab();
		editArea.value = iR.curTab.content;
		//fix the style
		$('.selected').removeClass('selected');
		$('#tab' + iR.curTab.tabId).addClass('selected');
	}
}

iR.addTab = function() {
	var newTab = new iR.StatDocTab();
	iR.statTabs[newTab.idString] = newTab;
	return newTab
}

iR.selectTab = function(aTabId) {
	var editArea = document.getElementById('scriptArea');
	//save the data
	iR.curTab.content = editArea.value;
	iR.clearSavedSelection()
	//load the new tab's data
	iR.curTab = iR.statTabs["tab" + aTabId];
	editArea.value = iR.curTab.content;
	//fix the style
	$('.selected').removeClass('selected');
	$('#tab' + aTabId).addClass('selected');
}

iR.loadFile = function(fid, fname, inNewTab) {
	if (inNewTab) {
		//need to create a new tab with the name of the file
		var theTab = iR.addTab()
		iR.selectTab(theTab.tabId)
	}
	$("#" + iR.curTab.idString).children().first().html(fname)
	jQuery.ajax({
		url: '/fd/files/' + fid,
		type: 'GET',
		dataType: 'text',
		success: function(data) {
				iR.clearSavedSelection()
				iR.curTab.curFileId = fid
				$('#scriptArea').val(data)
				iR.curTab.savedContent = data
				iR.curTab.content = data
			}
	})
}

iR.loadFileFromDialog = function(fid, fname) {
	$('#openDialog').dialog('close')
	iR.loadFile(fid, fname, document.getElementById('iR-openfile-newTab').checked);
	return false;
}

iR.displayDirectory = function(data) {
	var nc = "<h1>" + data['path'] + "</h1>\n"
	nc += "<table id=\"iR-ftree-table\">\n"
	if (data['id'] != this.displayedDir['id']) {
		nc += "<tr><td>&lt;parent directory&gt;</td></tr>\n"
	}
	for (i=0; i < data['entries'].length; i++) {
		var afile = data['entries'][i]
		if (afile['size']) {
			nc += '<tr><td class="ir-fn"><a href="#" class="ir-ft-lk"' + 
				'" onclick="return iR.loadFileFromDialog(' + afile['id'] + ', \'' + afile['name'] + '\');">' +
				afile["name"] + "</a></td>";
			nc += "<td class=\"ir-fs\">" + afile['size'] + "</td>"
		} else { //directory
			nc += '<tr><td class="ir-fn"><a href="#" class="ir-ft-lk"' + 
				'" onclick="return iR.loadDirectory(' + i + ');">' +
				afile["name"] + "</a></td>";
		}
		nc + "</tr>\n"
	}
	nc += "</table>"
	var destDiv = document.getElementById('filePickerContent')
	destDiv.innerHTML = nc	
}

iR.loadDirectory = function(idx) {
	//find the appropriate directory to load based on it's id
	var newDir = this.displayedDir['entries'][idx]
	iR.displayDirectory(newDir)
	this.displayedDir = newDir
	return false;
}

iR.loadOpenFileTree = function() {
	jQuery.getJSON("/fd/ftree", function(data) {
		this.fileTree = data
		iR.displayedDir = data
		iR.displayDirectory(data)
	})
}

iR.clearSavedSelection = function() {
	this.selectionStart=0
	this.selectionEnd=0
}

iR.increaseFontSize = function() {
	var curSize = parseFloat($('body').css('font-size'))
	if (curSize < 36)
		$('body').css('font-size', curSize + 2)
}

iR.decreaseFontSize = function() {
	var curSize = parseFloat($('body').css('font-size'))
	if (curSize > 8)
		$('body').css('font-size', curSize - 2)
}

iR.updateUserList = function(users) {
	$('#userTable tbody').empty()
	for (i=0; i < users.length; i++) {
		var str = '<tr><td>' + users[i]['login'] + '</td></tr>'
		$("#userTable > tbody:last").append(str)
	}
}

iR.showUsers = function() {
//	$('#userTabW').animate({right: 0});
	$('#userTabContent').show("slide", {direction: "left"}, 1000);
}

iR.hideUsers = function() {
//	$('#userTabW').animate({right:-200});
	$('#userTabContent').hide("slide", {direction: "right"}, 1000);
}

iR.hideMenuIfDisplayed = function(linkRef) {
	$(linkRef).closest('.sf-menu').hideSuperfishUl();
}

iR.doSetup = function() {
}