import { Save, AlertCircle, Clock, Users, CheckCircle2 } from 'lucide-react'

export default function SettingsPage() {
    return (
        <div className="space-y-6">
            {/* Settings Sections */}
            <div className="space-y-6">
                {/* Donation Rules */}
                <SettingsSection
                    title="Donation Rules"
                    description="Configure platform rules for food donations"
                    icon={Clock}
                >
                    <SettingItem
                        label="Maximum Pickup Window"
                        description="Maximum time allowed between donation posting and pickup"
                        input={
                            <select className="w-48 rounded-md border border-input bg-background px-3 py-2 text-sm">
                                <option>4 hours</option>
                                <option>6 hours</option>
                                <option>8 hours</option>
                                <option>12 hours</option>
                            </select>
                        }
                    />
                    <SettingItem
                        label="Auto-Expire Donations"
                        description="Automatically expire donations if not picked up"
                        input={
                            <label className="relative inline-flex cursor-pointer items-center">
                                <input type="checkbox" className="peer sr-only" defaultChecked />
                                <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white"></div>
                            </label>
                        }
                    />
                    <SettingItem
                        label="Minimum Food Quantity"
                        description="Minimum amount required for donation posting (kg)"
                        input={
                            <input
                                type="number"
                                defaultValue={5}
                                className="w-32 rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                        }
                    />
                </SettingsSection>

                {/* Volunteer Settings */}
                <SettingsSection
                    title="Volunteer Settings"
                    description="Configure volunteer assignment rules"
                    icon={Users}
                >
                    <SettingItem
                        label="Max Delivery Distance"
                        description="Maximum distance radius for volunteer assignments"
                        input={
                            <select className="w-48 rounded-md border border-input bg-background px-3 py-2 text-sm">
                                <option>5 km</option>
                                <option>10 km</option>
                                <option>15 km</option>
                                <option>20 km</option>
                            </select>
                        }
                    />
                    <SettingItem
                        label="Test Pass Threshold"
                        description="Minimum score required to pass volunteer test (%)"
                        input={
                            <input
                                type="number"
                                defaultValue={60}
                                className="w-32 rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                        }
                    />
                    <SettingItem
                        label="Max Failed Attempts"
                        description="Maximum test retries before lockout"
                        input={
                            <input
                                type="number"
                                defaultValue={3}
                                className="w-32 rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                        }
                    />
                </SettingsSection>

                {/* Verification Settings */}
                <SettingsSection
                    title="Verification Settings"
                    description="Auto-approval rules for user verifications"
                    icon={CheckCircle2}
                >
                    <SettingItem
                        label="Auto-Approve Vendors"
                        description="Automatically approve vendors with valid business license"
                        input={
                            <label className="relative inline-flex cursor-pointer items-center">
                                <input type="checkbox" className="peer sr-only" />
                                <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white"></div>
                            </label>
                        }
                    />
                    <SettingItem
                        label="Require NGO Registration Number"
                        description="Make registration number mandatory for NGO verification"
                        input={
                            <label className="relative inline-flex cursor-pointer items-center">
                                <input type="checkbox" className="peer sr-only" defaultChecked />
                                <div className="peer h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-white"></div>
                            </label>
                        }
                    />
                </SettingsSection>

                {/* Notification Templates */}
                <SettingsSection
                    title="Notification Templates"
                    description="Customize email and push notification messages"
                    icon={AlertCircle}
                >
                    <SettingItem
                        label="Approval Email Subject"
                        description="Email subject line for approval notifications"
                        input={
                            <input
                                type="text"
                                defaultValue="Welcome to NoMoreWaste!"
                                className="flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                        }
                        fullWidth
                    />
                    <SettingItem
                        label="Rejection Email Subject"
                        description="Email subject line for rejection notifications"
                        input={
                            <input
                                type="text"
                                defaultValue="Registration Update Required"
                                className="flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                        }
                        fullWidth
                    />
                </SettingsSection>
            </div>

            {/* Save Button */}
            <div className="flex justify-end border-t pt-6">
                <button className="inline-flex items-center gap-2 rounded-md bg-primary px-6 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                    <Save className="h-4 w-4" />
                    Save Changes
                </button>
            </div>
        </div>
    )
}

function SettingsSection({
    title,
    description,
    icon: Icon,
    children,
}: {
    title: string
    description: string
    icon: any
    children: React.ReactNode
}) {
    return (
        <div className="rounded-lg border bg-card p-6">
            <div className="mb-6 flex items-start gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                    <Icon className="h-5 w-5 text-primary" />
                </div>
                <div>
                    <h2 className="text-lg font-semibold">{title}</h2>
                    <p className="text-sm text-muted-foreground">{description}</p>
                </div>
            </div>
            <div className="space-y-6">{children}</div>
        </div>
    )
}

function SettingItem({
    label,
    description,
    input,
    fullWidth,
}: {
    label: string
    description: string
    input: React.ReactNode
    fullWidth?: boolean
}) {
    return (
        <div className={`flex ${fullWidth ? 'flex-col gap-2' : 'items-center justify-between'}`}>
            <div className={fullWidth ? '' : 'flex-1'}>
                <p className="text-sm font-medium">{label}</p>
                <p className="text-xs text-muted-foreground">{description}</p>
            </div>
            {input}
        </div>
    )
}
