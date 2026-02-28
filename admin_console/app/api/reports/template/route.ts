import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
    try {
        const { templateId, format } = await request.json()

        // Generate template report based on ID
        const reportData = generateTemplateData(templateId)

        // Convert to requested format
        let blob: Blob
        let contentType: string

        switch (format.toUpperCase()) {
            case 'PDF':
                blob = generatePDFTemplate(reportData, templateId)
                contentType = 'application/pdf'
                break
            case 'CSV':
                blob = generateCSVTemplate(reportData, templateId)
                contentType = 'text/csv'
                break
            case 'EXCEL':
                blob = generateExcelTemplate(reportData, templateId)
                contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                break
            default:
                throw new Error('Unsupported format')
        }

        return new NextResponse(blob, {
            headers: {
                'Content-Type': contentType,
                'Content-Disposition': `attachment; filename=${templateId}-report-${Date.now()}.${format.toLowerCase()}`,
            },
        })
    } catch (error) {
        console.error('Template download error:', error)
        return NextResponse.json(
            { error: 'Failed to download report' },
            { status: 500 }
        )
    }
}

function generateTemplateData(templateId: string) {
    const templates: Record<string, any> = {
        '1': {
            title: 'Monthly Impact Report',
            data: {
                totalFood: '2,450 kg',
                mealsServed: '12,435',
                co2Prevented: '1,250 kg',
                donations: 1247,
            },
        },
        '2': {
            title: 'User Activity Report',
            data: {
                activeDonors: 234,
                activeNGOs: 45,
                fulfillmentRate: '94.2%',
                newUsers: 67,
            },
        },
        '3': {
            title: 'Delivery Performance',
            data: {
                successRate: '96.8%',
                avgPickupTime: '32 minutes',
                volunteerReliability: '98.5%',
                completedDeliveries: 1189,
            },
        },
    }

    return templates[templateId] || templates['1']
}

function generatePDFTemplate(data: any, templateId: string): Blob {
    const pdfContent = `%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
>>
endobj
4 0 obj
<<
/Length 400
>>
stream
BT
/F1 24 Tf
50 750 Td
(NoMoreWaste Admin Dashboard) Tj
0 -30 Td
/F1 18 Tf
(${data.title}) Tj
0 -40 Td
/F1 12 Tf
(Generated: ${new Date().toLocaleString()}) Tj
0 -40 Td
/F1 14 Tf
(Report Data:) Tj
0 -30 Td
/F1 12 Tf
${Object.entries(data.data)
            .map(([key, value]) => {
                const label = key.replace(/([A-Z])/g, ' $1').trim()
                return `(${label}: ${value}) Tj 0 -20 Td`
            })
            .join('\n')}
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000300 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
750
%%EOF`

    return new Blob([pdfContent], { type: 'application/pdf' })
}

function generateCSVTemplate(data: any, templateId: string): Blob {
    const csv = `
"Report Title","${data.title}"
"Generated At","${new Date().toLocaleString()}"

"Metric","Value"
${Object.entries(data.data)
            .map(([key, value]) => `"${key.replace(/([A-Z])/g, ' $1').trim()}","${value}"`)
            .join('\n')}
    `.trim()

    return new Blob([csv], { type: 'text/csv' })
}

function generateExcelTemplate(data: any, templateId: string): Blob {
    return generateCSVTemplate(data, templateId)
}
